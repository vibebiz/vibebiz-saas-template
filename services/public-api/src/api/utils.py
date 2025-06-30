"""
Utility functions for the VibeBiz Public API
"""

import re
import secrets
import string
from datetime import UTC, datetime
from typing import Any
from urllib.parse import urlparse

from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt.

    Args:
        password: The plain text password to hash

    Returns:
        The hashed password as a string
    """
    return pwd_context.hash(password)


def verify_password(password: str, hashed: str) -> bool:
    """
    Verify a password against its hash

    Args:
        password: The plain text password to verify
        hashed: The hashed password to check against

    Returns:
        True if password matches hash, False otherwise
    """
    return pwd_context.verify(password, hashed)


def generate_secure_token(length: int = 32) -> str:
    """
    Generate a cryptographically secure random token

    Args:
        length: The length of the token (default: 32)

    Returns:
        A secure random token string
    """
    alphabet = string.ascii_letters + string.digits
    return "".join(secrets.choice(alphabet) for _ in range(length))


def create_slug(name: str) -> str:
    """
    Create a URL-friendly slug from a name

    Args:
        name: The name to convert to a slug

    Returns:
        A URL-friendly slug
    """
    # Convert to lowercase and replace non-alphanumeric with hyphens
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower())
    # Remove leading/trailing hyphens
    slug = slug.strip("-")
    return slug


def sanitize_filename(filename: str) -> str:
    """
    Sanitize a filename by removing dangerous characters

    Args:
        filename: The filename to sanitize

    Returns:
        A sanitized filename
    """
    # Remove path traversal attempts
    filename = filename.replace("..", "")
    filename = filename.replace("/", "")
    filename = filename.replace("\\", "")

    # Keep only alphanumeric, dots, hyphens, underscores
    sanitized = re.sub(r"[^a-zA-Z0-9._-]", "", filename)

    # Ensure it's not empty
    if not sanitized:
        sanitized = "file"

    return sanitized


def get_utc_now() -> datetime:
    """
    Get current UTC datetime

    Returns:
        Current datetime in UTC timezone
    """
    return datetime.now(UTC)


def format_datetime(dt: datetime) -> str:
    """
    Format datetime as ISO string

    Args:
        dt: The datetime to format

    Returns:
        ISO formatted datetime string
    """
    return dt.isoformat()


def parse_datetime(dt_str: str) -> datetime | None:
    """
    Parse ISO datetime string.

    Args:
        dt_str: ISO datetime string.

    Returns:
        Parsed datetime object or None if invalid.
    """
    if not isinstance(dt_str, str):
        return None
    try:
        return datetime.fromisoformat(dt_str)
    except ValueError:
        return None


def validate_email(email: str) -> bool:
    """
    Validate email format.

    Args:
        email: The email to validate.

    Returns:
        True if email format is valid, False otherwise.
    """
    if not isinstance(email, str):
        return False
    # A simple regex for email validation
    pattern = r"^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$"
    if not re.match(pattern, email):
        return False
    return True


def validate_url(url: str) -> bool:
    """
    Validate URL format

    Args:
        url: The URL to validate

    Returns:
        True if URL format is valid, False otherwise
    """
    try:
        result = urlparse(url)
        return all([result.scheme, result.netloc])
    except Exception:
        return False


def mask_sensitive_data(
    data: dict[str, Any], sensitive_keys: tuple[str, ...] = ()
) -> dict[str, Any]:
    """
    Mask sensitive data in a dictionary for logging.

    Args:
        data: Dictionary containing data to mask.
        sensitive_keys: Tuple of keys to mask.

    Returns:
        Dictionary with sensitive values masked.
    """
    default_sensitive_keys = {
        "password",
        "token",
        "secret",
        "key",
        "auth",
        "credential",
        "jwt",
        "session",
        "cookie",
    }
    # Combine default and custom sensitive keys
    keys_to_mask = default_sensitive_keys.union(sensitive_keys)

    masked_data: dict[str, Any] = {}
    for key, value in data.items():
        # Check if the key contains any of the sensitive key strings
        if any(k in key for k in keys_to_mask):
            if isinstance(value, str):
                if len(value) > 4:
                    # Mask long strings, showing first and last 2 chars
                    masked_data[key] = value[:2] + "**********" + value[-2:]
                else:
                    # For short strings, mask completely
                    masked_data[key] = "***"
            else:
                # Mask non-string values completely
                masked_data[key] = "***"
        elif isinstance(value, dict):
            # Recursively mask nested dictionaries
            masked_data[key] = mask_sensitive_data(value, sensitive_keys)
        else:
            masked_data[key] = value
    return masked_data
