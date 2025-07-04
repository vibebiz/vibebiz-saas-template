"""
Minimal FastAPI application for testing multi-tenant isolation.
This provides the endpoints expected by cross-cutting tests.
"""

import os
import uuid
from datetime import UTC, datetime
from typing import Any

from fastapi import Depends, FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, ConfigDict

# Import utilities

app = FastAPI(
    title="VibeBiz Public API",
    description="Public API for VibeBiz SaaS Platform",
    version="1.0.0",
)


# Secure CORS configuration
def get_allowed_origins() -> list[str]:
    """Get allowed origins from environment variables."""
    origins_str = os.getenv(
        "ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:3001"
    )
    return [origin.strip() for origin in origins_str.split(",") if origin.strip()]


# Add CORS middleware with secure configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=get_allowed_origins(),
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers=["*"],
    max_age=3600,  # Cache preflight requests for 1 hour
)


# Custom exception handler to match expected error format
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": exc.status_code == 403 and "Forbidden" or "Bad Request",
            "message": exc.detail,
        },
    )


# Pydantic models
class Document(BaseModel):
    id: str
    title: str
    organization_id: str
    created_at: datetime
    updated_at: datetime


class DocumentCreate(BaseModel):
    title: str


class Dashboard(BaseModel):
    organization_id: str
    recent_documents: list[Document]
    team_members: list[dict[str, Any]]


class ReportRequest(BaseModel):
    type: str
    period: str
    model_config = ConfigDict(extra="allow")


class ReportResponse(BaseModel):
    report_id: str
    status: str


# Mock data storage (in memory for testing)
mock_documents = {
    "org-1": [
        Document(
            id="doc-1",
            title="Organization 1 Document 1",
            organization_id="org-1",
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        ),
        Document(
            id="doc-2",
            title="Organization 1 Document 2",
            organization_id="org-1",
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        ),
    ],
    "org-2": [
        Document(
            id="doc-3",
            title="Organization 2 Document 1",
            organization_id="org-2",
            created_at=datetime.now(UTC),
            updated_at=datetime.now(UTC),
        ),
    ],
}

mock_users = {
    "user-1": {"id": "user-1", "organization_id": "org-1", "role": "admin"},
    "user-2": {"id": "user-2", "organization_id": "org-2", "role": "user"},
}


# Authentication dependency
async def get_current_user(authorization: str = Header(...)) -> dict[str, Any]:
    """Extract user from Authorization header."""
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header")

    token = authorization.replace("Bearer ", "")
    # In a real app, this would validate the JWT token
    # For testing, we'll use a simple mapping
    user_mapping = {
        "user-1-token": "user-1",
        "user-2-token": "user-2",
        "user-3-token": "user-3",
    }

    user_id = user_mapping.get(token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")

    return mock_users[user_id]


# Organization validation dependency
async def validate_organization(
    request: Request,
    current_user: dict[str, Any] = Depends(get_current_user),  # noqa: B008
) -> str:
    """Validate that user belongs to the specified organization."""
    x_organization_id = request.headers.get("X-Organization-ID")

    if not x_organization_id:
        raise HTTPException(
            status_code=400, detail="X-Organization-ID header is required"
        )

    if current_user["organization_id"] != x_organization_id:
        raise HTTPException(
            status_code=403, detail="User is not a member of the specified organization"
        )

    return x_organization_id


@app.get("/health")
async def health_check() -> dict[str, Any]:
    """Health check endpoint."""
    return {"status": "healthy", "timestamp": datetime.now(UTC)}


@app.get("/api/v1/documents")
async def get_documents(
    organization_id: str = Depends(validate_organization),  # noqa: B008
    current_user: dict[str, Any] = Depends(get_current_user),  # noqa: B008
) -> list[Document]:
    """Get documents for the current organization."""
    documents = mock_documents.get(organization_id, [])
    return documents


@app.post("/api/v1/documents")
async def create_document(
    document: DocumentCreate,
    organization_id: str = Depends(validate_organization),  # noqa: B008
    current_user: dict[str, Any] = Depends(get_current_user),  # noqa: B008
) -> Document:
    """Create a new document."""
    new_document = Document(
        id=f"doc-{uuid.uuid4()}",
        title=document.title,
        organization_id=organization_id,
        created_at=datetime.now(UTC),
        updated_at=datetime.now(UTC),
    )

    if organization_id not in mock_documents:
        mock_documents[organization_id] = []

    mock_documents[organization_id].append(new_document)
    return new_document


@app.get("/api/v1/dashboard")
async def get_dashboard(
    organization_id: str = Depends(validate_organization),  # noqa: B008
    current_user: dict[str, Any] = Depends(get_current_user),  # noqa: B008
) -> Dashboard:
    """Get dashboard data for the current organization."""
    documents = mock_documents.get(organization_id, [])
    team_members = (
        [{"id": "user-1", "name": "User 1", "organization_id": organization_id}]
        if organization_id == "org-1"
        else [{"id": "user-2", "name": "User 2", "organization_id": organization_id}]
    )

    return Dashboard(
        organization_id=organization_id,
        recent_documents=documents[:5],  # Last 5 documents
        team_members=team_members,
    )


@app.post("/api/v1/reports/generate")
async def generate_report(
    request: Request,
    organization_id: str = Depends(validate_organization),  # noqa: B008
    current_user: dict[str, Any] = Depends(get_current_user),  # noqa: B008
) -> JSONResponse:
    """Generate a report for the current organization."""
    # In a real implementation, this would process the request body
    # For now, we just generate a report ID and return processing status
    report_id = f"report-{uuid.uuid4()}"
    return JSONResponse(
        status_code=202, content={"report_id": report_id, "status": "processing"}
    )


@app.get("/api/v1/reports/{report_id}")
async def get_report(
    report_id: str,
    organization_id: str = Depends(validate_organization),  # noqa: B008
    current_user: dict[str, Any] = Depends(get_current_user),  # noqa: B008
) -> dict[str, Any]:
    """Get a specific report."""
    # Mock report data
    return {
        "id": report_id,
        "organization_id": organization_id,
        "type": "usage",
        "period": "monthly",
        "status": "completed",
        "data": {
            "total_documents": len(mock_documents.get(organization_id, [])),
            "total_users": 1,
        },
    }


if __name__ == "__main__":
    import uvicorn

    # Use localhost for development, configurable via environment
    host = os.getenv("HOST", "127.0.0.1")  # noqa: S104
    uvicorn.run(app, host=host, port=8000)
