"""
Pydantic models for the application
"""

from __future__ import annotations

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, EmailStr


class User(BaseModel):
    """
    User model
    """

    model_config = ConfigDict(frozen=True)

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

    model_config = ConfigDict(frozen=True)

    id: str
    name: str
    slug: str
    settings: dict[str, Any] | None = None
    created_at: datetime
    updated_at: datetime


class Role(str, Enum):
    """
    Enumeration for user roles
    """

    OWNER = "owner"
    ADMIN = "admin"
    MEMBER = "member"
    BILLING = "billing"


class ProjectStatus(str, Enum):
    """
    Enumeration for project statuses
    """

    ACTIVE = "active"
    INACTIVE = "inactive"
    ARCHIVED = "archived"


class InvitationStatus(str, Enum):
    """
    Enumeration for invitation statuses
    """

    PENDING = "pending"
    ACCEPTED = "accepted"
    EXPIRED = "expired"


class Project(BaseModel):
    """
    Project model
    """

    model_config = ConfigDict(frozen=True)

    id: str
    organization_id: str
    name: str
    slug: str
    description: str | None = None
    status: ProjectStatus
    creator_id: str
    created_at: datetime
    updated_at: datetime


class OrganizationMember(BaseModel):
    """
    OrganizationMember model
    """

    model_config = ConfigDict(frozen=True)

    id: str
    user_id: str
    organization_id: str
    role: Role
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
    role: Role
    token_hash: str
    status: InvitationStatus
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
    role: Role
    iat: int
    exp: int
    jti: str
