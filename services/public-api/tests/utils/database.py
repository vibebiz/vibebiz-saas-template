"""
Database utilities for integration testing
"""

import pathlib
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
                password="test_password",  # nosec B106 # noqa: S106
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
        Create database tables for testing by executing schema.sql
        Note: In a real implementation, this would use Alembic migrations
        """
        if not self.engine:
            await self.setup_database()

        if not self.engine:
            raise RuntimeError("Database engine not initialized")

        schema_path = pathlib.Path(__file__).parent / "schema.sql"
        if not schema_path.is_file():
            raise FileNotFoundError(f"Schema file not found at {schema_path}")

        schema_sql = schema_path.read_text()

        async with self.engine.begin() as conn:
            await conn.execute(text(schema_sql))

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
