"""
Pytest configuration and shared fixtures for VibeBiz Public API
"""

import asyncio
from collections.abc import Callable, Generator
from datetime import UTC, datetime
from typing import Any
from unittest.mock import AsyncMock, MagicMock

import pytest


@pytest.fixture(scope="session")
def event_loop() -> Generator[asyncio.AbstractEventLoop, None, None]:
    """
    Create an instance of the default event loop for the test session.
    This is required for async tests to work properly.
    """
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def mock_user() -> dict[str, Any]:
    """
    Create a mock user object for testing

    Returns:
        Dictionary representing a user with common fields
    """
    return {
        "id": "user-123",
        "email": "test@example.com",
        "full_name": "Test User",
        "avatar_url": "https://example.com/avatar.jpg",
        "created_at": datetime.now(UTC).isoformat(),
        "updated_at": datetime.now(UTC).isoformat(),
        "status": "active",
    }


@pytest.fixture
def mock_organization() -> dict[str, Any]:
    """
    Create a mock organization object for testing

    Returns:
        Dictionary representing an organization with common fields
    """
    return {
        "id": "org-123",
        "name": "Test Organization",
        "slug": "test-org",
        "settings": {"theme": "light", "notifications": True},
        "created_at": datetime.now(UTC).isoformat(),
        "updated_at": datetime.now(UTC).isoformat(),
        "status": "active",
    }


@pytest.fixture
def mock_project() -> dict[str, Any]:
    """
    Create a mock project object for testing

    Returns:
        Dictionary representing a project with common fields
    """
    return {
        "id": "project-123",
        "organization_id": "org-123",
        "name": "Test Project",
        "slug": "test-project",
        "description": "A test project for unit testing",
        "status": "active",
        "created_by": "user-123",
        "created_at": datetime.now(UTC).isoformat(),
        "updated_at": datetime.now(UTC).isoformat(),
    }


@pytest.fixture
def mock_database_session() -> AsyncMock:
    """
    Create a mock database session for testing

    Returns:
        AsyncMock object that simulates a database session
    """
    session = AsyncMock()
    session.commit = AsyncMock()
    session.rollback = AsyncMock()
    session.close = AsyncMock()
    session.flush = AsyncMock()
    session.refresh = AsyncMock()
    return session


@pytest.fixture
def mock_jwt_payload() -> dict[str, Any]:
    """
    Create a mock JWT payload for testing authentication

    Returns:
        Dictionary representing a decoded JWT token payload
    """
    return {
        "sub": "user-123",
        "email": "test@example.com",
        "org_id": "org-123",
        "role": "admin",
        "iat": int(datetime.now(UTC).timestamp()),
        "exp": int(datetime.now(UTC).timestamp()) + 3600,  # 1 hour from now
        "jti": "token-123",
    }


@pytest.fixture
def mock_api_response() -> Callable[[Any, int, str], dict[str, Any]]:
    """
    Create a mock API response structure

    Returns:
        Dictionary representing a standard API response
    """

    def _create_response(
        data: Any = None, status: int = 200, message: str = "Success"
    ) -> dict[str, Any]:
        return {
            "data": data,
            "status": status,
            "message": message,
            "timestamp": datetime.now(UTC).isoformat(),
        }

    return _create_response


@pytest.fixture
def mock_pagination() -> dict[str, Any]:
    """
    Create a mock pagination object for testing list endpoints

    Returns:
        Dictionary representing pagination metadata
    """
    return {
        "page": 1,
        "page_size": 20,
        "total": 100,
        "total_pages": 5,
        "has_next": True,
        "has_prev": False,
    }


@pytest.fixture
def mock_request_context() -> dict[str, Any]:
    """
    Create a mock request context for testing middleware and dependencies

    Returns:
        Dictionary representing request context
    """
    return {
        "request_id": "req-123",
        "user_id": "user-123",
        "organization_id": "org-123",
        "ip_address": "127.0.0.1",
        "user_agent": "pytest-test-client",
        "timestamp": datetime.now(UTC).isoformat(),
    }


@pytest.fixture
def mock_redis_client() -> MagicMock:
    """
    Create a mock Redis client for testing caching and sessions

    Returns:
        MagicMock object that simulates a Redis client
    """
    redis_mock = MagicMock()
    redis_mock.get = AsyncMock(return_value=None)
    redis_mock.set = AsyncMock(return_value=True)
    redis_mock.delete = AsyncMock(return_value=1)
    redis_mock.exists = AsyncMock(return_value=False)
    redis_mock.expire = AsyncMock(return_value=True)
    return redis_mock


@pytest.fixture
def sample_file_upload() -> dict[str, Any]:
    """
    Create a sample file upload object for testing file handling

    Returns:
        Dictionary representing an uploaded file
    """
    return {
        "filename": "test_document.pdf",
        "content_type": "application/pdf",
        "size": 1024 * 1024,  # 1MB
        "content": b"mock file content for testing",
    }


# Test data factory functions
def create_test_user(**overrides: Any) -> dict[str, Any]:
    """
    Factory function to create test user data with overrides

    Args:
        **overrides: Fields to override in the default user data

    Returns:
        Dictionary representing a test user
    """
    default_user = {
        "id": f"user-{id(overrides)}",
        "email": f"test{id(overrides)}@example.com",
        "full_name": "Test User",
        "status": "active",
        "created_at": datetime.now(UTC).isoformat(),
        "updated_at": datetime.now(UTC).isoformat(),
    }
    default_user.update(overrides)
    return default_user


def create_test_organization(**overrides: Any) -> dict[str, Any]:
    """
    Factory function to create test organization data with overrides

    Args:
        **overrides: Fields to override in the default organization data

    Returns:
        Dictionary representing a test organization
    """
    default_org = {
        "id": f"org-{id(overrides)}",
        "name": "Test Organization",
        "slug": f"test-org-{id(overrides)}",
        "status": "active",
        "created_at": datetime.now(UTC).isoformat(),
        "updated_at": datetime.now(UTC).isoformat(),
    }
    default_org.update(overrides)
    return default_org


# Pytest configuration
def pytest_configure(config: pytest.Config) -> None:
    """
    Pytest configuration hook
    """
    # Register custom markers
    config.addinivalue_line(
        "markers", "unit: Fast unit tests with no external dependencies"
    )
    config.addinivalue_line(
        "markers", "integration: Integration tests with external dependencies"
    )
    config.addinivalue_line("markers", "slow: Tests that take longer than usual to run")
    config.addinivalue_line(
        "markers", "auth: Authentication and authorization related tests"
    )
    config.addinivalue_line("markers", "api: API endpoint tests")
    config.addinivalue_line("markers", "database: Database related tests")
    config.addinivalue_line("markers", "security: Security related tests")
    config.addinivalue_line("markers", "performance: Performance and load tests")


def pytest_collection_modifyitems(config: pytest.Config, items: list) -> None:
    """
    Modify test collection to add default markers
    """
    for item in items:
        # Add 'unit' marker to tests that don't have other markers
        if not any(
            marker.name
            in [
                "integration",
                "slow",
                "auth",
                "api",
                "database",
                "security",
                "performance",
            ]
            for marker in item.iter_markers()
        ):
            item.add_marker(pytest.mark.unit)
