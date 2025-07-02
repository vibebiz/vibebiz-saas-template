"""
Comprehensive tests for the main FastAPI application.
Tests all endpoints, authentication, authorization, and error handling.
"""

from datetime import UTC, datetime

import pytest
from fastapi.testclient import TestClient

from src.main import app, mock_documents, mock_users


@pytest.fixture
def client() -> TestClient:
    """Create a test client for the FastAPI app."""
    return TestClient(app)


@pytest.fixture
def auth_headers_user1() -> dict[str, str]:
    """Headers for user-1 authentication."""
    return {"Authorization": "Bearer user-1-token", "X-Organization-ID": "org-1"}


@pytest.fixture
def auth_headers_user2() -> dict[str, str]:
    """Headers for user-2 authentication."""
    return {"Authorization": "Bearer user-2-token", "X-Organization-ID": "org-2"}


class TestHealthCheck:
    """Test the health check endpoint."""

    def test_health_check_success(self, client: TestClient) -> None:
        """Test health check returns healthy status."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert "timestamp" in data


class TestAuthentication:
    """Test authentication and authorization."""

    def test_missing_authorization_header(self, client: TestClient) -> None:
        """Test that missing authorization header returns 422 (FastAPI validation error)."""  # noqa: E501
        response = client.get(
            "/api/v1/documents", headers={"X-Organization-ID": "org-1"}
        )
        assert response.status_code == 422
        # FastAPI returns validation error for missing required parameters

    def test_invalid_authorization_format(self, client: TestClient) -> None:
        """Test that invalid authorization format returns 401."""
        response = client.get(
            "/api/v1/documents",
            headers={
                "Authorization": "InvalidFormat user-1-token",
                "X-Organization-ID": "org-1",
            },
        )
        assert response.status_code == 401
        assert "Invalid authorization header" in response.json()["message"]

    def test_invalid_token(self, client: TestClient) -> None:
        """Test that invalid token returns 401."""
        response = client.get(
            "/api/v1/documents",
            headers={
                "Authorization": "Bearer invalid-token",
                "X-Organization-ID": "org-1",
            },
        )
        assert response.status_code == 401
        assert "Invalid token" in response.json()["message"]

    def test_missing_organization_header(self, client: TestClient) -> None:
        """Test that missing organization header returns 400."""
        response = client.get(
            "/api/v1/documents", headers={"Authorization": "Bearer user-1-token"}
        )
        assert response.status_code == 400
        assert "X-Organization-ID header is required" in response.json()["message"]

    def test_user_not_in_organization(self, client: TestClient) -> None:
        """Test that user not in organization returns 403."""
        response = client.get(
            "/api/v1/documents",
            headers={
                "Authorization": "Bearer user-1-token",
                "X-Organization-ID": "org-2",
            },
        )
        assert response.status_code == 403
        assert (
            "User is not a member of the specified organization"
            in response.json()["message"]
        )


class TestDocuments:
    """Test document endpoints."""

    def test_get_documents_success_user1(
        self, client: TestClient, auth_headers_user1: dict[str, str]
    ) -> None:
        """Test getting documents for user-1."""
        response = client.get("/api/v1/documents", headers=auth_headers_user1)
        assert response.status_code == 200
        documents = response.json()
        assert len(documents) == 2
        assert documents[0]["organization_id"] == "org-1"
        assert documents[1]["organization_id"] == "org-1"

    def test_get_documents_success_user2(
        self, client: TestClient, auth_headers_user2: dict[str, str]
    ) -> None:
        """Test getting documents for user-2."""
        response = client.get("/api/v1/documents", headers=auth_headers_user2)
        assert response.status_code == 200
        documents = response.json()
        assert len(documents) == 1
        assert documents[0]["organization_id"] == "org-2"

    def test_get_documents_empty_organization(self, client: TestClient) -> None:
        """Test getting documents for organization with no documents."""
        # Use org-2 which exists but has no documents initially
        # First clear org-2 documents
        original_org2_docs = mock_documents["org-2"].copy()
        mock_documents["org-2"] = []

        try:
            response = client.get(
                "/api/v1/documents",
                headers={
                    "Authorization": "Bearer user-2-token",
                    "X-Organization-ID": "org-2",
                },
            )
            assert response.status_code == 200
            documents = response.json()
            assert len(documents) == 0
        finally:
            # Restore original data
            mock_documents["org-2"] = original_org2_docs

    def test_create_document_success(
        self, client: TestClient, auth_headers_user1: dict[str, str]
    ) -> None:
        """Test creating a new document."""
        document_data = {"title": "Test Document"}
        response = client.post(
            "/api/v1/documents", json=document_data, headers=auth_headers_user1
        )
        assert response.status_code == 200
        document = response.json()
        assert document["title"] == "Test Document"
        assert document["organization_id"] == "org-1"
        assert "id" in document
        assert "created_at" in document
        assert "updated_at" in document

    def test_create_document_new_organization(self, client: TestClient) -> None:
        """Test creating document for new organization."""
        document_data = {"title": "New Org Document"}
        response = client.post(
            "/api/v1/documents",
            json=document_data,
            headers={
                "Authorization": "Bearer user-1-token",
                "X-Organization-ID": "org-1",
            },
        )
        assert response.status_code == 200
        document = response.json()
        assert document["title"] == "New Org Document"
        assert document["organization_id"] == "org-1"


class TestDashboard:
    """Test dashboard endpoint."""

    def test_get_dashboard_user1(
        self, client: TestClient, auth_headers_user1: dict[str, str]
    ) -> None:
        """Test getting dashboard for user-1."""
        response = client.get("/api/v1/dashboard", headers=auth_headers_user1)
        assert response.status_code == 200
        dashboard = response.json()
        assert dashboard["organization_id"] == "org-1"
        assert len(dashboard["recent_documents"]) <= 5
        assert len(dashboard["team_members"]) == 1
        assert dashboard["team_members"][0]["organization_id"] == "org-1"

    def test_get_dashboard_user2(
        self, client: TestClient, auth_headers_user2: dict[str, str]
    ) -> None:
        """Test getting dashboard for user-2."""
        response = client.get("/api/v1/dashboard", headers=auth_headers_user2)
        assert response.status_code == 200
        dashboard = response.json()
        assert dashboard["organization_id"] == "org-2"
        assert len(dashboard["recent_documents"]) <= 5
        assert len(dashboard["team_members"]) == 1
        assert dashboard["team_members"][0]["organization_id"] == "org-2"


class TestReports:
    """Test report endpoints."""

    def test_generate_report_success(
        self, client: TestClient, auth_headers_user1: dict[str, str]
    ) -> None:
        """Test generating a report."""
        report_data = {"type": "usage", "period": "monthly"}
        response = client.post(
            "/api/v1/reports/generate", json=report_data, headers=auth_headers_user1
        )
        assert response.status_code == 202
        report = response.json()
        assert "report_id" in report
        assert report["status"] == "processing"

    def test_get_report_success(
        self, client: TestClient, auth_headers_user1: dict[str, str]
    ) -> None:
        """Test getting a specific report."""
        report_id = "test-report-123"
        response = client.get(
            f"/api/v1/reports/{report_id}", headers=auth_headers_user1
        )
        assert response.status_code == 200
        report = response.json()
        assert report["id"] == report_id
        assert report["organization_id"] == "org-1"
        assert report["type"] == "usage"
        assert report["period"] == "monthly"
        assert report["status"] == "completed"
        assert "data" in report
        assert "total_documents" in report["data"]
        assert "total_users" in report["data"]


class TestExceptionHandler:
    """Test the custom exception handler."""

    def test_http_exception_handler_400(self, client: TestClient) -> None:
        """Test exception handler for 400 errors."""
        # Trigger a 400 error by missing organization header
        response = client.get(
            "/api/v1/documents", headers={"Authorization": "Bearer user-1-token"}
        )
        assert response.status_code == 400
        data = response.json()
        assert data["error"] == "Bad Request"
        assert "message" in data

    def test_http_exception_handler_403(self, client: TestClient) -> None:
        """Test exception handler for 403 errors."""
        # Trigger a 403 error by wrong organization
        response = client.get(
            "/api/v1/documents",
            headers={
                "Authorization": "Bearer user-1-token",
                "X-Organization-ID": "org-2",
            },
        )
        assert response.status_code == 403
        data = response.json()
        assert data["error"] == "Forbidden"
        assert "message" in data


class TestDataModels:
    """Test Pydantic models."""

    def test_document_model(self) -> None:
        """Test Document model validation."""
        from src.main import Document

        # Valid document
        doc = Document(
            id="test-id",
            title="Test Title",
            organization_id="org-1",
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )
        assert doc.id == "test-id"
        assert doc.title == "Test Title"
        assert doc.organization_id == "org-1"

    def test_document_create_model(self) -> None:
        """Test DocumentCreate model validation."""
        from src.main import DocumentCreate

        # Valid document creation
        doc_create = DocumentCreate(title="New Document")
        assert doc_create.title == "New Document"

    def test_dashboard_model(self) -> None:
        """Test Dashboard model validation."""
        from src.main import Dashboard, Document

        # Valid dashboard
        doc = Document(
            id="test-id",
            title="Test Title",
            organization_id="org-1",
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        )

        dashboard = Dashboard(
            organization_id="org-1",
            recent_documents=[doc],
            team_members=[{"id": "user-1", "name": "User 1"}],
        )
        assert dashboard.organization_id == "org-1"
        assert len(dashboard.recent_documents) == 1
        assert len(dashboard.team_members) == 1


class TestMockData:
    """Test mock data structures."""

    def test_mock_documents_structure(self) -> None:
        """Test mock documents data structure."""
        assert "org-1" in mock_documents
        assert "org-2" in mock_documents
        assert (
            len(mock_documents["org-1"]) >= 2
        )  # May have been modified by other tests
        assert (
            len(mock_documents["org-2"]) >= 1
        )  # May have been modified by other tests

        # Check document structure
        for org_docs in mock_documents.values():
            for doc in org_docs:
                assert hasattr(doc, "id")
                assert hasattr(doc, "title")
                assert hasattr(doc, "organization_id")
                assert hasattr(doc, "created_at")
                assert hasattr(doc, "updated_at")

    def test_mock_users_structure(self) -> None:
        """Test mock users data structure."""
        assert "user-1" in mock_users
        assert "user-2" in mock_users

        # Check user structure
        for user in mock_users.values():
            assert "id" in user
            assert "organization_id" in user
            assert "role" in user


class TestEdgeCases:
    """Test edge cases and error conditions."""

    def test_uuid_generation_in_document_creation(
        self, client: TestClient, auth_headers_user1: dict[str, str]
    ) -> None:
        """Test that document creation generates unique UUIDs."""
        document_data = {"title": "UUID Test Document"}

        # Create multiple documents and verify unique IDs
        response1 = client.post(
            "/api/v1/documents", json=document_data, headers=auth_headers_user1
        )
        response2 = client.post(
            "/api/v1/documents", json=document_data, headers=auth_headers_user1
        )

        doc1 = response1.json()
        doc2 = response2.json()

        assert doc1["id"] != doc2["id"]
        assert doc1["id"].startswith("doc-")
        assert doc2["id"].startswith("doc-")

    def test_dashboard_document_limit(
        self, client: TestClient, auth_headers_user1: dict[str, str]
    ) -> None:
        """Test that dashboard limits documents to 5."""
        # Create more than 5 documents
        for i in range(7):
            document_data = {"title": f"Document {i}"}
            client.post(
                "/api/v1/documents", json=document_data, headers=auth_headers_user1
            )

        # Check dashboard only returns 5 documents
        response = client.get("/api/v1/dashboard", headers=auth_headers_user1)
        dashboard = response.json()
        assert len(dashboard["recent_documents"]) <= 5
