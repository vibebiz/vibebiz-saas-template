from collections.abc import Iterator

import pytest
from fastapi.testclient import TestClient

from src.main import app, mock_documents, mock_users


@pytest.fixture(scope="module")
def client() -> TestClient:
    """
    Test client for the FastAPI application.
    """
    return TestClient(app)


@pytest.fixture
def auth_headers_user1() -> dict[str, str]:
    """
    Authentication headers for user 1.
    """
    return {"Authorization": "Bearer user-1-token", "X-Organization-ID": "org-1"}


@pytest.fixture
def auth_headers_user2() -> dict[str, str]:
    """
    Authentication headers for user 2.
    """
    return {"Authorization": "Bearer user-2-token", "X-Organization-ID": "org-2"}


@pytest.fixture(autouse=True)
def reset_mock_data() -> Iterator[None]:
    """
    Automatically reset mock data before each test.
    """
    original_users = mock_users.copy()
    original_documents = {
        org_id: docs.copy() for org_id, docs in mock_documents.items()
    }

    yield

    mock_users.clear()
    mock_users.update(original_users)
    mock_documents.clear()
    mock_documents.update(original_documents)
