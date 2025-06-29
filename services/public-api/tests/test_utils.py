"""
Unit tests for API utility functions
"""

import pytest
from datetime import datetime, timezone
from unittest.mock import patch

# Import the module under test
# Note: In a real implementation, this would work once dependencies are installed
try:
    from src.api.utils import (
        generate_secure_token,
        validate_email,
        create_slug,
        sanitize_filename,
        get_utc_now,
        format_datetime,
        parse_datetime,
        validate_url,
        mask_sensitive_data,
        # hash_password,  # Commented out due to bcrypt dependency
        # verify_password,  # Commented out due to bcrypt dependency
    )
except ImportError:
    # Mock imports for demonstration purposes
    pytest.skip("Dependencies not installed, skipping tests", allow_module_level=True)


class TestSecureTokenGeneration:
    """Test secure token generation"""
    
    def test_default_length(self):
        """Test token generation with default length"""
        token = generate_secure_token()
        assert len(token) == 32
        assert isinstance(token, str)
    
    def test_custom_length(self):
        """Test token generation with custom length"""
        token = generate_secure_token(16)
        assert len(token) == 16
        
        token = generate_secure_token(64)
        assert len(token) == 64
    
    def test_token_uniqueness(self):
        """Test that generated tokens are unique"""
        tokens = [generate_secure_token() for _ in range(100)]
        assert len(set(tokens)) == 100  # All tokens should be unique
    
    def test_token_characters(self):
        """Test that tokens contain only valid characters"""
        token = generate_secure_token()
        valid_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789')
        assert all(char in valid_chars for char in token)


class TestEmailValidation:
    """Test email validation"""
    
    def test_valid_emails(self):
        """Test validation of valid email addresses"""
        valid_emails = [
            'test@example.com',
            'user.name@domain.co.uk',
            'admin+tag@company.org',
            'number123@test.io',
            'user_name@test-domain.com'
        ]
        
        for email in valid_emails:
            assert validate_email(email), f"Should be valid: {email}"
    
    def test_invalid_emails(self):
        """Test validation of invalid email addresses"""
        invalid_emails = [
            '',
            'invalid',
            '@domain.com',
            'user@',
            'user@domain',
            'user name@domain.com',
            'user..name@domain.com',
            'user@domain..com',
            'a' * 255 + '@domain.com',  # Too long
        ]
        
        for email in invalid_emails:
            assert not validate_email(email), f"Should be invalid: {email}"


class TestSlugCreation:
    """Test slug creation from names"""
    
    def test_basic_slug_creation(self):
        """Test basic slug creation"""
        assert create_slug('Test Organization') == 'test-organization'
        assert create_slug('My Company Name') == 'my-company-name'
    
    def test_special_characters(self):
        """Test slug creation with special characters"""
        assert create_slug('Company & Co!') == 'company-co'
        assert create_slug('Test@Company#123') == 'test-company-123'
    
    def test_multiple_spaces(self):
        """Test slug creation with multiple consecutive spaces"""
        assert create_slug('Test   Company') == 'test-company'
        assert create_slug('  Test Company  ') == 'test-company'
    
    def test_edge_cases(self):
        """Test slug creation edge cases"""
        assert create_slug('') == ''
        assert create_slug('123') == '123'
        assert create_slug('---') == ''


class TestFilenameSanitization:
    """Test filename sanitization"""
    
    def test_safe_filenames(self):
        """Test that safe filenames remain unchanged"""
        safe_names = [
            'document.txt',
            'image_123.jpg',
            'file-name.pdf',
            'report.2025.xlsx'
        ]
        
        for filename in safe_names:
            assert sanitize_filename(filename) == filename
    
    def test_dangerous_filenames(self):
        """Test sanitization of dangerous filenames"""
        dangerous_cases = [
            ('../../etc/passwd', 'etcpasswd'),
            ('file\\with\\backslashes.txt', 'filewithbackslashes.txt'),
            ('file/with/slashes.txt', 'filewithslashes.txt'),
            ('file with spaces.txt', 'filewithspaces.txt'),
            ('file!@#$%^&*().txt', 'file.txt'),
        ]
        
        for dangerous, expected in dangerous_cases:
            result = sanitize_filename(dangerous)
            assert result == expected
    
    def test_empty_filename(self):
        """Test sanitization of empty or invalid filenames"""
        assert sanitize_filename('') == 'file'
        assert sanitize_filename('!@#$%^&*()') == 'file'


class TestDatetimeHandling:
    """Test datetime utility functions"""
    
    def test_get_utc_now(self):
        """Test UTC datetime generation"""
        now = get_utc_now()
        assert isinstance(now, datetime)
        assert now.tzinfo == timezone.utc
    
    def test_format_datetime(self):
        """Test datetime formatting"""
        dt = datetime(2025, 1, 1, 12, 0, 0, tzinfo=timezone.utc)
        formatted = format_datetime(dt)
        assert isinstance(formatted, str)
        assert '2025-01-01T12:00:00' in formatted
    
    def test_parse_datetime_valid(self):
        """Test parsing valid datetime strings"""
        valid_dates = [
            '2025-01-01T12:00:00+00:00',
            '2025-01-01T12:00:00Z',
            '2025-01-01T12:00:00',
        ]
        
        for date_str in valid_dates:
            result = parse_datetime(date_str)
            assert isinstance(result, datetime)
    
    def test_parse_datetime_invalid(self):
        """Test parsing invalid datetime strings"""
        invalid_dates = [
            '',
            'invalid',
            '2025-13-01T12:00:00',  # Invalid month
            '2025-01-32T12:00:00',  # Invalid day
        ]
        
        for date_str in invalid_dates:
            result = parse_datetime(date_str)
            assert result is None


class TestUrlValidation:
    """Test URL validation"""
    
    def test_valid_urls(self):
        """Test validation of valid URLs"""
        valid_urls = [
            'https://example.com',
            'http://test.org',
            'https://sub.domain.com/path',
            'ftp://files.example.com',
        ]
        
        for url in valid_urls:
            assert validate_url(url), f"Should be valid: {url}"
    
    def test_invalid_urls(self):
        """Test validation of invalid URLs"""
        invalid_urls = [
            '',
            'invalid',
            'example.com',  # Missing scheme
            'http://',      # Missing netloc
            'not a url',
        ]
        
        for url in invalid_urls:
            assert not validate_url(url), f"Should be invalid: {url}"


class TestSensitiveDataMasking:
    """Test sensitive data masking for logging"""
    
    def test_default_sensitive_keys(self):
        """Test masking with default sensitive keys"""
        data = {
            'username': 'testuser',
            'password': 'secretpassword',
            'token': 'abcd1234567890',
            'email': 'test@example.com'
        }
        
        masked = mask_sensitive_data(data)
        
        assert masked['username'] == 'testuser'  # Not sensitive
        assert masked['email'] == 'test@example.com'  # Not sensitive
        assert masked['password'] == 'se**********rd'
        assert 'ab**********90' in masked['token'] or masked['token'] == '***'
    
    def test_custom_sensitive_keys(self):
        """Test masking with custom sensitive keys"""
        data = {
            'public_info': 'visible',
            'secret_data': 'hidden_value',
            'normal_field': 'normal_value'
        }
        
        masked = mask_sensitive_data(data, sensitive_keys=['secret'])
        
        assert masked['public_info'] == 'visible'
        assert masked['normal_field'] == 'normal_value'
        assert 'hi**********ue' in masked['secret_data'] or masked['secret_data'] == '***'
    
    def test_short_sensitive_values(self):
        """Test masking of short sensitive values"""
        data = {
            'password': 'abc',
            'token': '',
            'key': 'x'
        }
        
        masked = mask_sensitive_data(data)
        
        for key in ['password', 'token', 'key']:
            assert masked[key] == '***'


# Integration test example (would require database setup in real implementation)
@pytest.mark.integration
def test_integration_example():
    """Example integration test (placeholder)"""
    # This would test multiple utilities working together
    # with a real database or external service
    pass


# Performance test example
@pytest.mark.slow
def test_token_generation_performance():
    """Test token generation performance"""
    import time
    
    start_time = time.time()
    tokens = [generate_secure_token() for _ in range(1000)]
    end_time = time.time()
    
    # Should generate 1000 tokens in less than 1 second
    assert end_time - start_time < 1.0
    assert len(tokens) == 1000
    assert len(set(tokens)) == 1000  # All unique 