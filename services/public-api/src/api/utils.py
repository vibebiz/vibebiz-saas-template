"""
Utility functions for the VibeBiz Public API
"""

import re
import secrets
import string
from datetime import datetime, timezone
from typing import Any, Dict, Optional
from urllib.parse import urlparse

import bcrypt


def hash_password(password: str) -> str:
    """
    Hash a password using bcrypt with cost factor 12
    
    Args:
        password: The plain text password to hash
        
    Returns:
        The hashed password as a string
    """
    salt = bcrypt.gensalt(rounds=12)
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')


def verify_password(password: str, hashed: str) -> bool:
    """
    Verify a password against its hash
    
    Args:
        password: The plain text password to verify
        hashed: The hashed password to check against
        
    Returns:
        True if password matches hash, False otherwise
    """
    try:
        return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
    except ValueError:
        return False


def generate_secure_token(length: int = 32) -> str:
    """
    Generate a cryptographically secure random token
    
    Args:
        length: The length of the token (default: 32)
        
    Returns:
        A secure random token string
    """
    alphabet = string.ascii_letters + string.digits
    return ''.join(secrets.choice(alphabet) for _ in range(length))


def validate_email(email: str) -> bool:
    """
    Validate an email address format
    
    Args:
        email: The email address to validate
        
    Returns:
        True if email format is valid, False otherwise
    """
    if not email or len(email) > 254:
        return False
    
    # Check for consecutive dots
    if '..' in email:
        return False
    
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def create_slug(name: str) -> str:
    """
    Create a URL-friendly slug from a name
    
    Args:
        name: The name to convert to a slug
        
    Returns:
        A URL-friendly slug
    """
    # Convert to lowercase and replace non-alphanumeric with hyphens
    slug = re.sub(r'[^a-z0-9]+', '-', name.lower())
    # Remove leading/trailing hyphens
    slug = slug.strip('-')
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
    filename = filename.replace('..', '')
    filename = filename.replace('/', '')
    filename = filename.replace('\\', '')
    
    # Keep only alphanumeric, dots, hyphens, underscores
    sanitized = re.sub(r'[^a-zA-Z0-9._-]', '', filename)
    
    # Ensure it's not empty
    if not sanitized:
        sanitized = 'file'
    
    return sanitized


def get_utc_now() -> datetime:
    """
    Get current UTC datetime
    
    Returns:
        Current datetime in UTC timezone
    """
    return datetime.now(timezone.utc)


def format_datetime(dt: datetime) -> str:
    """
    Format datetime as ISO string
    
    Args:
        dt: The datetime to format
        
    Returns:
        ISO formatted datetime string
    """
    return dt.isoformat()


def parse_datetime(dt_str: str) -> Optional[datetime]:
    """
    Parse ISO datetime string
    
    Args:
        dt_str: ISO datetime string
        
    Returns:
        Parsed datetime object or None if invalid
    """
    try:
        return datetime.fromisoformat(dt_str.replace('Z', '+00:00'))
    except (ValueError, AttributeError):
        return None


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


def mask_sensitive_data(data: Dict[str, Any], sensitive_keys: Optional[list] = None) -> Dict[str, Any]:
    """
    Mask sensitive data in a dictionary for logging
    
    Args:
        data: Dictionary containing data to mask
        sensitive_keys: List of keys to mask (default: common sensitive keys)
        
    Returns:
        Dictionary with sensitive values masked
    """
    if sensitive_keys is None:
        sensitive_keys = [
            'password', 'token', 'secret', 'key', 'auth', 
            'credential', 'jwt', 'session', 'cookie'
        ]
    
    masked_data = data.copy()
    
    for key, value in data.items():
        if any(sensitive_key in key.lower() for sensitive_key in sensitive_keys):
            if isinstance(value, str) and len(value) > 4:
                # Use a fixed number of asterisks (10) for consistency
                masked_data[key] = value[:2] + '*' * 10 + value[-2:]
            else:
                masked_data[key] = '***'
    
    return masked_data 