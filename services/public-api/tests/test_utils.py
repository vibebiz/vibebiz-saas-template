"""
Unit tests for API utility functions
"""

from datetime import UTC, datetime

import pytest

# Import the module under test
# Note: In a real implementation, this would work once dependencies are installed
try:
    from src.api.utils import (
        create_slug,
        format_datetime,
        generate_secure_token,
        get_utc_now,
        hash_password,
        mask_sensitive_data,
        parse_datetime,
        sanitize_filename,
        validate_email,
        validate_url,
        verify_password,
    )
except ImportError:
    # Mock imports for demonstration purposes
    pytest.skip("Dependencies not installed, skipping tests", allow_module_level=True)


class TestSecureTokenGeneration:
    """Test secure token generation"""

    def test_default_length(self) -> None:
        """Test token generation with default length"""
        token = generate_secure_token()
        assert len(token) == 32  # nosec
        assert isinstance(token, str)  # nosec

    def test_custom_length(self) -> None:
        """Test token generation with custom length"""
        token = generate_secure_token(16)
        assert len(token) == 16  # nosec

        token = generate_secure_token(64)
        assert len(token) == 64  # nosec

    def test_token_uniqueness(self) -> None:
        """Test that generated tokens are unique"""
        tokens = [generate_secure_token() for _ in range(100)]
        assert len(set(tokens)) == 100  # nosec # All tokens should be unique

    def test_token_characters(self) -> None:
        """Test that tokens contain only valid characters"""
        token = generate_secure_token()
        valid_chars = set(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        )
        assert all(char in valid_chars for char in token)  # nosec


class TestEmailValidation:
    """Test email validation"""

    def test_valid_emails(self) -> None:
        """Test validation of valid email addresses"""
        valid_emails = [
            "test@example.com",
            "user.name@domain.co.uk",
            "admin+tag@company.org",
            "number123@test.io",
            "user_name@test-domain.com",
        ]

        for email in valid_emails:
            assert validate_email(email), f"Should be valid: {email}"  # nosec

    def test_invalid_emails(self) -> None:
        """Test validation of invalid email addresses"""
        invalid_emails = [
            "",
            "invalid",
            "@domain.com",
            "user@",
            "user@domain",
            "user name@domain.com",
            "user..name@domain.com",
            "user@domain..com",
            "a" * 255 + "@domain.com",  # Too long
        ]

        for email in invalid_emails:
            assert not validate_email(email), f"Should be invalid: {email}"  # nosec


class TestSlugCreation:
    """Test slug creation from names"""

    def test_basic_slug_creation(self) -> None:
        """Test basic slug creation"""
        assert create_slug("Test Organization") == "test-organization"  # nosec
        assert create_slug("My Company Name") == "my-company-name"  # nosec

    def test_special_characters(self) -> None:
        """Test slug creation with special characters"""
        assert create_slug("Company & Co!") == "company-co"  # nosec
        assert create_slug("Test@Company#123") == "test-company-123"  # nosec

    def test_multiple_spaces(self) -> None:
        """Test slug creation with multiple consecutive spaces"""
        assert create_slug("Test   Company") == "test-company"  # nosec
        assert create_slug("  Test Company  ") == "test-company"  # nosec

    def test_edge_cases(self) -> None:
        """Test slug creation edge cases"""
        assert create_slug("") == ""  # nosec
        assert create_slug("123") == "123"  # nosec
        assert create_slug("---") == ""  # nosec


class TestFilenameSanitization:
    """Test filename sanitization"""

    def test_safe_filenames(self) -> None:
        """Test that safe filenames remain unchanged"""
        safe_filenames = [
            "document.pdf",
            "image-01.jpg",
            "archive.tar.gz",
            "data_2025_Q1.csv",
            "report.2025.xlsx",
        ]

        for filename in safe_filenames:
            assert sanitize_filename(filename) == filename  # nosec

    def test_dangerous_filenames(self) -> None:
        """Test sanitization of dangerous filenames"""
        dangerous_map = {
            "../../etc/passwd": "etcpasswd",
            "file\\with\\backslashes.txt": "filewithbackslashes.txt",
            "file/with/slashes.txt": "filewithslashes.txt",
            "file with spaces.txt": "filewithspaces.txt",
            "file!@#$%^&*().txt": "file.txt",
        }

        for dangerous, sanitized in dangerous_map.items():
            assert sanitize_filename(dangerous) == sanitized  # nosec

    def test_empty_filename(self) -> None:
        """Test sanitization of empty or invalid filenames"""
        assert sanitize_filename("") == "file"  # nosec
        assert sanitize_filename("   ") == "file"  # nosec


class TestDatetimeHandling:
    """Test datetime utility functions"""

    def test_get_utc_now(self) -> None:
        """Test UTC datetime generation"""
        now = get_utc_now()
        assert isinstance(now, datetime)  # nosec
        assert now.tzinfo == UTC  # nosec

    def test_format_datetime(self) -> None:
        """Test datetime formatting"""
        dt = datetime(2025, 1, 1, 12, 0, 0, tzinfo=UTC)
        assert format_datetime(dt) == "2025-01-01T12:00:00+00:00"  # nosec

    def test_parse_datetime_valid(self) -> None:
        """Test parsing valid datetime strings"""
        valid_dates = [
            "2025-01-01T12:00:00+00:00",
            "2025-01-01T12:00:00Z",
            "2025-01-01T12:00:00",
        ]

        for date_str in valid_dates:
            result = parse_datetime(date_str)
            assert isinstance(result, datetime)  # nosec

    def test_parse_datetime_invalid(self) -> None:
        """Test parsing invalid datetime strings"""
        invalid_dates = [
            "",
            "invalid",
            "2025-13-01T12:00:00",  # Invalid month
            "2025-01-32T12:00:00",  # Invalid day
        ]

        for date_str in invalid_dates:
            result = parse_datetime(date_str)
            assert result is None  # nosec


class TestUrlValidation:
    """Test URL validation"""

    def test_valid_urls(self) -> None:
        """Test validation of valid URLs"""
        valid_urls = [
            "https://example.com",
            "http://test.org",
            "https://sub.domain.com/path",
            "ftp://files.example.com",
        ]

        for url in valid_urls:
            assert validate_url(url), f"Should be valid: {url}"  # nosec

    def test_invalid_urls(self) -> None:
        """Test validation of invalid URLs"""
        invalid_urls = [
            "",
            "invalid",
            "example.com",  # Missing scheme
            "http://",  # Missing netloc
            "not a url",
        ]

        for url in invalid_urls:
            assert not validate_url(url), f"Should be invalid: {url}"  # nosec


class TestSensitiveDataMasking:
    """Test sensitive data masking for logging"""

    def test_default_sensitive_keys(self) -> None:
        """Test masking with default sensitive keys"""
        data = {
            "username": "testuser",
            "password": "secretpassword",
            "token": "abcd1234567890",  # gitleaks:allow
            "email": "test@example.com",
        }

        masked = mask_sensitive_data(data)

        assert masked["username"] == "testuser"  # nosec # Not sensitive
        assert masked["email"] == "test@example.com"  # nosec # Not sensitive
        assert masked["password"] == "se**********rd"  # nosec
        assert "ab**********90" in masked["token"] or masked["token"] == "***"  # nosec

    def test_custom_sensitive_keys(self) -> None:
        """Test masking with custom sensitive keys"""
        data = {
            "public_info": "visible",
            "secret_data": "hidden_value",
            "normal_field": "normal_value",
        }

        masked = mask_sensitive_data(data, sensitive_keys=("secret_data",))

        assert masked["public_info"] == "visible"  # nosec
        assert masked["normal_field"] == "normal_value"  # nosec
        assert (  # nosec
            "hi**********ue" in masked["secret_data"] or masked["secret_data"] == "***"
        )

    def test_short_sensitive_values(self) -> None:
        """Test masking of short sensitive values"""
        data = {"password": "abc", "token": "", "key": "x"}

        masked = mask_sensitive_data(data)

        for key in ["password", "token", "key"]:
            assert masked[key] == "***"  # nosec


class TestPasswordHashing:
    """Test password hashing and verification"""

    def test_hash_and_verify_password(self) -> None:
        """Test that a password can be hashed and verified"""
        password = "secure_password_123"  # nosec
        hashed = hash_password(password)

        assert hashed != password  # nosec
        assert verify_password(password, hashed)  # nosec

    def test_verify_incorrect_password(self) -> None:
        """Test that an incorrect password fails verification"""
        password = "secure_password_123"  # nosec
        hashed = hash_password(password)

        assert not verify_password("wrong_password", hashed)  # nosec


# Performance test example
@pytest.mark.slow
def test_token_generation_performance() -> None:
    """Test token generation performance"""
    import time

    start_time = time.time()
    tokens = [generate_secure_token() for _ in range(1000)]
    end_time = time.time()

    # Should generate 1000 tokens in less than 1 second
    assert end_time - start_time < 1.0  # nosec
    assert len(tokens) == 1000  # nosec
    assert len(set(tokens)) == 1000  # nosec # All unique
