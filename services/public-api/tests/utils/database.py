"""
Database utilities for integration testing
"""

from collections.abc import AsyncGenerator

import pytest
from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from testcontainers.postgres import PostgresContainer


class DatabaseTestManager:
    """
    Manages PostgreSQL database for integration tests using testcontainers
    """

    def __init__(self) -> None:
        self.container: PostgresContainer | None = None
        self.engine: AsyncEngine | None = None
        self.session_factory: async_sessionmaker[AsyncSession] | None = None
        self._db_url: str | None = None

    def start_container(self) -> str:
        """
        Start PostgreSQL container and return connection URL

        Returns:
            Database connection URL
        """
        if self.container is None:
            self.container = PostgresContainer(
                image="postgres:15-alpine",
                username="test_user",
                password="test_password",  # nosec B106
                dbname="test_db",
                port=5432,
            )
            self.container.start()

        if self.container is None:
            raise RuntimeError("Container not started")
        # Get connection URL and convert to async format
        sync_url = self.container.get_connection_url()
        # Parse URL to rebuild with asyncpg driver
        from urllib.parse import urlparse

        parsed = urlparse(sync_url)
        self._db_url = f"postgresql+asyncpg://{parsed.username}:{parsed.password}@{parsed.hostname}:{parsed.port}{parsed.path}"
        return self._db_url

    def stop_container(self) -> None:
        """Stop PostgreSQL container"""
        if self.container:
            self.container.stop()
            self.container = None

    async def setup_database(self) -> None:
        """
        Set up database engine and session factory
        """
        if not self._db_url:
            self.start_container()

        self.engine = create_async_engine(
            self._db_url,
            echo=False,  # Set to True for SQL debugging
            pool_size=1,  # Single connection for testing
            max_overflow=0,  # No overflow connections
            pool_pre_ping=True,
            pool_recycle=300,
            connect_args={
                "server_settings": {
                    "application_name": "vibebiz_test",
                }
            },
        )

        self.session_factory = async_sessionmaker(
            self.engine,
            class_=AsyncSession,
            expire_on_commit=False,
        )

    async def create_tables(self) -> None:
        """
        Create database tables for testing
        Note: In a real implementation, this would use Alembic migrations
        """
        if not self.engine:
            await self.setup_database()

        if not self.engine:
            raise RuntimeError("Database engine not initialized")

        # Basic table creation for MVP stage
        # In production, this would use Alembic migrations
        # Split into separate statements to avoid asyncpg prepared statement limitations
        async with self.engine.begin() as conn:
            # Create extension
            await conn.execute(text('CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'))

            # Users table
            await conn.execute(
                text("""
                CREATE TABLE IF NOT EXISTS users (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    email VARCHAR(255) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    full_name VARCHAR(255),
                    avatar_url VARCHAR(512),
                    timezone VARCHAR(50) DEFAULT 'UTC',
                    locale VARCHAR(10) DEFAULT 'en',
                    phone VARCHAR(20),
                    status VARCHAR(20) DEFAULT 'active',
                    email_verified BOOLEAN DEFAULT FALSE,
                    metadata JSONB DEFAULT '{}',
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            """)
            )

            # Organizations table
            await conn.execute(
                text("""
                CREATE TABLE IF NOT EXISTS organizations (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    name VARCHAR(255) NOT NULL,
                    slug VARCHAR(100) UNIQUE NOT NULL,
                    settings JSONB DEFAULT '{}',
                    status VARCHAR(20) DEFAULT 'active',
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            """)
            )

            # Organization members table
            await conn.execute(
                text("""
                CREATE TABLE IF NOT EXISTS organization_members (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    organization_id UUID NOT NULL REFERENCES organizations(id),
                    user_id UUID NOT NULL REFERENCES users(id),
                    role VARCHAR(50) DEFAULT 'member',
                    status VARCHAR(20) DEFAULT 'active',
                    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    UNIQUE(organization_id, user_id)
                )
            """)
            )

            # Projects table
            await conn.execute(
                text("""
                CREATE TABLE IF NOT EXISTS projects (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    organization_id UUID NOT NULL REFERENCES organizations(id),
                    name VARCHAR(255) NOT NULL,
                    slug VARCHAR(100) NOT NULL,
                    description TEXT,
                    status VARCHAR(20) DEFAULT 'active',
                    created_by UUID REFERENCES users(id),
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
                    UNIQUE(organization_id, slug)
                )
            """)
            )

            # User sessions table
            await conn.execute(
                text("""
                CREATE TABLE IF NOT EXISTS user_sessions (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    user_id UUID NOT NULL REFERENCES users(id),
                    token_hash VARCHAR(255) NOT NULL,
                    refresh_token_hash VARCHAR(255),
                    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
                    revoked_at TIMESTAMP WITH TIME ZONE,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            """)
            )

            # Organization invitations table
            await conn.execute(
                text("""
                CREATE TABLE IF NOT EXISTS organization_invitations (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    organization_id UUID NOT NULL REFERENCES organizations(id),
                    email VARCHAR(255) NOT NULL,
                    role VARCHAR(50) DEFAULT 'member',
                    token_hash VARCHAR(255) NOT NULL,
                    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
                    invited_by UUID REFERENCES users(id),
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            """)
            )

            # Audit logs table
            await conn.execute(
                text("""
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
                    organization_id UUID REFERENCES organizations(id),
                    user_id UUID REFERENCES users(id),
                    action VARCHAR(100) NOT NULL,
                    resource_type VARCHAR(50),
                    resource_id UUID,
                    changes JSONB,
                    request_id VARCHAR(100),
                    ip_address INET,
                    user_agent TEXT,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
                )
            """)
            )

            # Create indexes for better performance
            indexes = [
                "CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)",
                "CREATE INDEX IF NOT EXISTS idx_users_status ON users(status)",
                (
                    "CREATE INDEX IF NOT EXISTS idx_organizations_slug "
                    "ON organizations(slug)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_organization_members_org_id "
                    "ON organization_members(organization_id)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_organization_members_user_id "
                    "ON organization_members(user_id)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_projects_org_id "
                    "ON projects(organization_id)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_projects_slug "
                    "ON projects(organization_id, slug)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id "
                    "ON user_sessions(user_id)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_user_sessions_token_hash "
                    "ON user_sessions(token_hash)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_audit_logs_org_id "
                    "ON audit_logs(organization_id)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id "
                    "ON audit_logs(user_id)"
                ),
                (
                    "CREATE INDEX IF NOT EXISTS idx_audit_logs_created_at "
                    "ON audit_logs(created_at)"
                ),
            ]

            for index_sql in indexes:
                await conn.execute(text(index_sql))

    async def cleanup_database(self) -> None:
        """
        Clean up database by dropping all tables
        """
        if not self.engine:
            return

        # Drop tables in reverse order to handle foreign key constraints
        drop_statements = [
            "DROP TABLE IF EXISTS audit_logs CASCADE",
            "DROP TABLE IF EXISTS organization_invitations CASCADE",
            "DROP TABLE IF EXISTS user_sessions CASCADE",
            "DROP TABLE IF EXISTS projects CASCADE",
            "DROP TABLE IF EXISTS organization_members CASCADE",
            "DROP TABLE IF EXISTS organizations CASCADE",
            "DROP TABLE IF EXISTS users CASCADE",
        ]

        async with self.engine.begin() as conn:
            for drop_sql in drop_statements:
                await conn.execute(text(drop_sql))

    async def get_session(self) -> AsyncSession:
        """
        Get a database session

        Returns:
            Async database session
        """
        if not self.session_factory:
            await self.setup_database()

        if not self.session_factory:
            raise RuntimeError("Session factory not initialized")

        return self.session_factory()

    async def rollback_transaction(self, session: AsyncSession) -> None:
        """
        Rollback database transaction for test isolation

        Args:
            session: Database session to rollback
        """
        await session.rollback()
        await session.close()


# Global database manager instance
_db_manager: DatabaseTestManager | None = None


def get_db_manager() -> DatabaseTestManager:
    """
    Get or create global database manager instance

    Returns:
        Database test manager instance
    """
    global _db_manager
    if _db_manager is None:
        _db_manager = DatabaseTestManager()
    return _db_manager


@pytest.fixture(scope="session")
async def db_manager() -> AsyncGenerator[DatabaseTestManager, None]:
    """
    Database manager fixture for integration tests

    Yields:
        Database test manager with running PostgreSQL container
    """
    manager = get_db_manager()
    manager.start_container()
    await manager.setup_database()
    await manager.create_tables()

    yield manager

    await manager.cleanup_database()
    manager.stop_container()


@pytest.fixture
async def db_session(
    db_manager: DatabaseTestManager,
) -> AsyncGenerator[AsyncSession, None]:
    """
    Database session fixture with automatic transaction rollback

    Args:
        db_manager: Database manager instance

    Yields:
        Database session that will be rolled back after test
    """
    session = await db_manager.get_session()

    try:
        # Use the session directly - let SQLAlchemy handle transactions
        yield session
    finally:
        # Close the session properly
        if session.is_active:
            await session.rollback()
        await session.close()


@pytest.fixture
async def clean_database(db_manager: DatabaseTestManager) -> AsyncGenerator[None, None]:
    """
    Fixture that ensures a clean database state

    Args:
        db_manager: Database manager instance

    Yields:
        None
    """
    # Clean up before test
    await db_manager.cleanup_database()
    await db_manager.create_tables()

    yield

    # Clean up after test
    await db_manager.cleanup_database()
    await db_manager.create_tables()
