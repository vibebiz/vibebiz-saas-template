"""
Integration tests for API utility functions.
Tests utilities in realistic scenarios and error conditions.
"""
# mypy: disable-error-code=index

from datetime import UTC, datetime

import pytest

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


@pytest.mark.integration
class TestPasswordSecurityIntegration:
    """Integration tests for password security functions"""

    def test_password_hashing_and_verification_workflow(self) -> None:
        """Test complete password workflow including edge cases"""
        # Test normal workflow
        password = "SecurePassword123!"  # nosec B105
        hashed = hash_password(password)
        assert verify_password(password, hashed)
        assert not verify_password("WrongPassword", hashed)

        # Test with special characters and edge cases
        special_passwords = [
            "!@#$%^&*()_+-=[]{}|;':\",./<>?",
            "unicode_πάσσwοrd_测试",
            "a" * 50,  # Long password (reduced to avoid bcrypt truncation)
            "x",  # Short password
        ]

        for pwd in special_passwords:
            hashed = hash_password(pwd)
            assert verify_password(pwd, hashed)
            assert not verify_password(pwd + "x", hashed)

    def test_password_hash_uniqueness(self) -> None:
        """Test that same password generates different hashes (salt)"""
        password = "TestPassword123"  # nosec B105
        hash1 = hash_password(password)
        hash2 = hash_password(password)

        # Different hashes due to salt
        assert hash1 != hash2

        # Both verify correctly
        assert verify_password(password, hash1)
        assert verify_password(password, hash2)


@pytest.mark.integration
class TestTokenSecurityIntegration:
    """Integration tests for secure token generation"""

    def test_token_generation_security_properties(self) -> None:
        """Test security properties of token generation"""
        # Generate many tokens to test randomness
        tokens = [generate_secure_token() for _ in range(1000)]

        # All should be unique
        assert len(set(tokens)) == 1000

        # All should be correct length
        assert all(len(token) == 32 for token in tokens)

        # All should contain only valid characters
        valid_chars = set(
            "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        )
        for token in tokens[:10]:  # Check first 10 for performance
            assert all(char in valid_chars for char in token)

    def test_custom_length_tokens(self) -> None:
        """Test custom length token generation"""
        lengths = [1, 16, 32, 64, 128, 256]
        for length in lengths:
            token = generate_secure_token(length)
            assert len(token) == length

        # Test edge case - zero length
        token = generate_secure_token(0)
        assert len(token) == 0


@pytest.mark.integration
class TestInputValidationIntegration:
    """Integration tests for input validation functions"""

    def test_email_validation_comprehensive(self) -> None:
        """Test email validation with comprehensive test cases"""
        # Valid emails from various domains
        valid_emails = [
            "user@example.com",
            "test+tag@domain.co.uk",
            "admin@subdomain.domain.org",
            "user123@test-domain.com",
            "a@b.co",
            "user.name+tag@example-domain.com",
            "x@domain.museum",
        ]

        for email in valid_emails:
            assert validate_email(email), f"Should be valid: {email}"

        # Invalid emails including edge cases
        invalid_emails = [
            "",  # Empty
            "invalid",  # No @
            "@domain.com",  # No local part
            "user@",  # No domain
            "user@domain",  # No TLD
            "user name@domain.com",  # Space in local
            "user@domain..com",  # Double dot in domain
            "user..name@domain.com",  # Double dot in local
            "a" * 65 + "@domain.com",  # Local part too long
            "user@" + "a" * 250 + ".com",  # Total too long
            "user@domain.",  # TLD missing
        ]

        # Test string emails
        for email in invalid_emails:
            assert not validate_email(email), f"Should be invalid: {email}"

        # Test non-string types separately
        for invalid_email in [None, 123]:
            assert not validate_email(invalid_email), (  # type: ignore[arg-type]
                f"Should be invalid: {invalid_email}"
            )  # nosec

    def test_url_validation_comprehensive(self) -> None:
        """Test URL validation with various schemes and formats"""
        valid_urls = [
            "https://example.com",
            "http://subdomain.domain.org",
            "ftp://files.example.com",
            "https://example.com/path/to/resource",
            "https://example.com:8080/path?query=value",
            "https://user:pass@example.com",
        ]

        for url in valid_urls:
            assert validate_url(url), f"Should be valid: {url}"

        invalid_urls = [
            "",  # Empty
            "not-a-url",  # No scheme
            "://example.com",  # No scheme
            "https://",  # No netloc
            "https:///path",  # No netloc
        ]

        # Test string URLs
        for url in invalid_urls:
            assert not validate_url(url), f"Should be invalid: {url}"

        # Test non-string types separately
        for invalid_url in [None, 123]:
            assert not validate_url(invalid_url), f"Should be invalid: {invalid_url}"  # type: ignore[arg-type]


@pytest.mark.integration
class TestStringProcessingIntegration:
    """Integration tests for string processing utilities"""

    def test_slug_creation_workflow(self) -> None:
        """Test slug creation in realistic usage scenarios"""
        test_cases = [
            ("My Company Name", "my-company-name"),
            ("Company & Associates", "company-associates"),
            ("Test@Domain#123", "test-domain-123"),
            ("  Spaced  Out  ", "spaced-out"),
            ("UPPERCASE", "uppercase"),
            ("mixed_Case-Example", "mixed-case-example"),
            ("123 Numbers 456", "123-numbers-456"),
            ("", ""),
            ("!@#$%^&*()", ""),
            ("---dashes---", "dashes"),
        ]

        for input_name, expected_slug in test_cases:
            result = create_slug(input_name)
            assert result == expected_slug, (
                f"Input: '{input_name}' -> Expected: '{expected_slug}', Got: '{result}'"
            )  # nosec

    def test_filename_sanitization_security(self) -> None:
        """Test filename sanitization for security"""
        dangerous_inputs = [
            ("../../etc/passwd", "etcpasswd"),
            ("..\\windows\\system32\\config", "windowssystem32config"),
            ("file/with/slashes.txt", "filewithslashes.txt"),
            ("file\\with\\backslashes.txt", "filewithbackslashes.txt"),
            ("file with spaces.txt", "filewithspaces.txt"),
            ("file!@#$%^&*().txt", "file.txt"),
            ("CON.txt", "CON.txt"),  # Windows reserved name
            ("", "file"),  # Empty filename
            ("   ", "file"),  # Whitespace only
            (".hidden", ".hidden"),  # Hidden file (allowed)
            ("file..txt", "filetxt"),  # Double dots get removed by regex
        ]

        for dangerous, expected in dangerous_inputs:
            result = sanitize_filename(dangerous)
            assert result == expected, (
                f"Input: '{dangerous}' -> Expected: '{expected}', Got: '{result}'"
            )  # nosec


@pytest.mark.integration
class TestDateTimeIntegration:
    """Integration tests for datetime utilities"""

    def test_datetime_workflow(self) -> None:
        """Test complete datetime workflow"""
        # Get current UTC time
        now = get_utc_now()
        assert isinstance(now, datetime)
        assert now.tzinfo == UTC

        # Format it
        formatted = format_datetime(now)
        assert isinstance(formatted, str)
        assert "T" in formatted  # nosec B101 # ISO format

        # Parse it back
        parsed = parse_datetime(formatted)
        assert isinstance(parsed, datetime)

        # Should be very close (within 1 second)
        time_diff = abs((parsed.replace(tzinfo=UTC) - now).total_seconds())
        assert time_diff < 1.0

    def test_parse_datetime_edge_cases(self) -> None:
        """Test datetime parsing edge cases"""
        # Valid formats
        valid_cases = [
            "2025-01-01T12:00:00+00:00",
            "2025-01-01T12:00:00Z",
            "2025-01-01T12:00:00",
            "2025-12-31T23:59:59.999999",
        ]

        for case in valid_cases:
            result = parse_datetime(case)
            assert result is not None, f"Should parse: {case}"

        # Invalid formats
        invalid_cases = [
            "",
            "not-a-date",
            "2025-13-01T12:00:00",  # Invalid month
            "2025-01-32T12:00:00",  # Invalid day
            "2025-01-01T25:00:00",  # Invalid hour
        ]

        # Test string cases
        for case in invalid_cases:
            result = parse_datetime(case)
            assert result is None, f"Should not parse: {case}"

        # Test non-string types separately
        for invalid_case in [None, 123]:
            result = parse_datetime(invalid_case)  # type: ignore[arg-type]
            assert result is None, f"Should not parse: {invalid_case}"


@pytest.mark.integration
class TestSensitiveDataMaskingIntegration:
    """Integration tests for sensitive data masking"""

    def test_comprehensive_data_masking(self) -> None:
        """Test masking in realistic data structures"""
        sensitive_data = {
            "user_id": "12345",
            "username": "testuser",
            "password": "SuperSecretPassword123!",
            "api_key": "sk_live_abcdef1234567890",
            "jwt_token": (
                "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9."
                "eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9."
                "TJVA95OrM7E2cBab30RMHrHDcEfxjoYZgeFONFh7HgQ"
            ),
            "secret_config": "config_secret_value",
            "auth_header": "Bearer abcd1234",
            "user_credential": "credential_value",
            "nested": {
                "password": "nested_password",
                "secret": "nested_secret",
                "normal_field": "normal_value",
            },
            "normal_field": "this should not be masked",
        }

        masked = mask_sensitive_data(sensitive_data)

        # Sensitive fields should be masked
        assert "password" in masked and masked["password"] != sensitive_data["password"]
        assert "api_key" in masked and masked["api_key"] != sensitive_data["api_key"]
        assert (
            "jwt_token" in masked and masked["jwt_token"] != sensitive_data["jwt_token"]
        )  # nosec
        assert (
            "secret_config" in masked
            and masked["secret_config"] != sensitive_data["secret_config"]
        )  # nosec
        assert (
            "auth_header" in masked
            and masked["auth_header"] != sensitive_data["auth_header"]
        )  # nosec
        assert (
            "user_credential" in masked
            and masked["user_credential"] != sensitive_data["user_credential"]
        )  # nosec

        # Normal fields should not be masked
        assert masked["user_id"] == sensitive_data["user_id"]
        assert masked["username"] == sensitive_data["username"]
        assert masked["normal_field"] == sensitive_data["normal_field"]

        # Nested sensitive data should be masked
        assert masked["nested"]["password"] != sensitive_data["nested"]["password"]
        assert masked["nested"]["secret"] != sensitive_data["nested"]["secret"]
        assert (
            masked["nested"]["normal_field"] == sensitive_data["nested"]["normal_field"]
        )  # nosec

    def test_custom_sensitive_keys(self) -> None:
        """Test masking with custom sensitive keys"""
        data = {
            "public_info": "not secret",
            "internal_code": "should_mask_this",
            "db_connection": "postgres://user:pass@host/db",
        }

        # Without custom keys
        result1 = mask_sensitive_data(data)
        assert (
            result1["internal_code"] == data["internal_code"]
        )  # Not masked by default

        # With custom keys
        result2 = mask_sensitive_data(data, ("internal", "connection"))
        assert result2["internal_code"] != data["internal_code"]  # Should be masked
        assert result2["db_connection"] != data["db_connection"]  # nosec # Should be masked
        assert result2["public_info"] == data["public_info"]  # nosec # Should not be masked

    def test_short_value_masking(self) -> None:
        """Test masking of short sensitive values"""
        data = {
            "password": "a",  # Very short
            "secret": "ab",  # Short
            "token": "abc",  # Short
            "key": "abcd",  # Short
            "long_password": "this_is_a_long_password_value",  # nosec B105 # Long
        }

        masked = mask_sensitive_data(data)

        # Short values should be completely masked
        assert masked["password"] == "***"  # nosec
        assert masked["secret"] == "***"  # nosec
        assert masked["token"] == "***"  # nosec
        assert masked["key"] == "***"  # nosec

        # Long values should show first/last chars
        long_masked_value = str(masked["long_password"])  # Cast to str for mypy
        assert long_masked_value.startswith("th")  # nosec # First 2 chars
        assert long_masked_value.endswith("ue")  # nosec # Last 2 chars
        assert "**********" in long_masked_value  # nosec # Middle masked

    def test_non_string_sensitive_values(self) -> None:
        """Test masking of non-string sensitive values"""
        data = {
            "password": 12345,  # Number
            "secret": None,  # None
            "token": ["a", "b"],  # List
            "key": {"nested": "value"},  # Dict
        }

        masked = mask_sensitive_data(data)

        # All non-string sensitive values should be masked as "***"
        assert masked["password"] == "***"  # nosec
        assert masked["secret"] == "***"  # nosec
        assert masked["token"] == "***"  # nosec
        assert masked["key"] == "***"  # nosec
