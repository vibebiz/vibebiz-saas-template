"""
Pydantic models for the application
"""

from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, EmailStr


class User(BaseModel):
    """
    User model
    """

    id: str
    email: EmailStr
    password_hash: str | None = None
    full_name: str | None = None
    avatar_url: str | None = None
    created_at: datetime
    updated_at: datetime


class Organization(BaseModel):
    """
    Organization model
    """

    id: str
    name: str
    slug: str
    settings: dict[str, Any] | None = None
    created_at: datetime
    updated_at: datetime


class Project(BaseModel):
    """
    Project model
    """

    id: str
    organization_id: str
    name: str
    slug: str
    description: str | None = None
    status: str
    creator_id: str
    created_at: datetime
    updated_at: datetime


class OrganizationMember(BaseModel):
    """
    OrganizationMember model
    """

    id: str
    user_id: str
    organization_id: str
    role: str
    created_at: datetime
    updated_at: datetime


class UserSession(BaseModel):
    """
    UserSession model
    """

    id: str
    user_id: str
    token_hash: str
    user_agent: str | None = None
    ip_address: str | None = None
    expires_at: datetime
    revoked_at: datetime | None = None
    created_at: datetime


class OrganizationInvitation(BaseModel):
    """
    OrganizationInvitation model
    """

    id: str
    organization_id: str
    email: EmailStr
    role: str
    token_hash: str
    status: str
    expires_at: datetime
    invited_by: str
    created_at: datetime


class AuditLog(BaseModel):
    """
    AuditLog model
    """

    id: str
    organization_id: str
    user_id: str | None = None
    action: str
    details: dict[str, Any] | None = None
    changes: dict[str, Any] | None = None
    request_id: str | None = None
    ip_address: str | None = None
    user_agent: str | None = None
    created_at: datetime


class JWTPayload(BaseModel):
    """
    JWTPayload model
    """

    sub: str  # user_id
    email: EmailStr
    org_id: str
    role: str
    iat: int
    exp: int
    jti: str
