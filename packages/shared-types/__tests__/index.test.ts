/**
 * Unit tests for shared types and utilities
 */

import {
  isValidEmail,
  createSlug,
  isUser,
  isOrganization,
  User,
  Organization
} from '../src/index';

describe('Email validation', () => {
  describe('isValidEmail', () => {
    test('should return true for valid email addresses', () => {
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'admin+tag@company.org',
        'number123@test.io'
      ];

      validEmails.forEach(email => {
        expect(isValidEmail(email)).toBe(true);
      });
    });

    test('should return false for invalid email addresses', () => {
      const invalidEmails = [
        '',
        'invalid',
        '@domain.com',
        'user@',
        'user@domain',
        'user name@domain.com',
        'user..name@domain.com'
      ];

      invalidEmails.forEach(email => {
        expect(isValidEmail(email)).toBe(false);
      });
    });
  });
});

describe('Slug creation', () => {
  describe('createSlug', () => {
    test('should convert name to lowercase slug', () => {
      expect(createSlug('Test Organization')).toBe('test-organization');
    });

    test('should replace spaces with hyphens', () => {
      expect(createSlug('My Company Name')).toBe('my-company-name');
    });

    test('should remove special characters', () => {
      expect(createSlug('Company & Co!')).toBe('company-co');
    });

    test('should handle multiple consecutive spaces', () => {
      expect(createSlug('Test   Company')).toBe('test-company');
    });

    test('should remove leading and trailing hyphens', () => {
      expect(createSlug('  Test Company  ')).toBe('test-company');
    });

    test('should handle empty string', () => {
      expect(createSlug('')).toBe('');
    });

    test('should handle numbers and letters', () => {
      expect(createSlug('Company 123')).toBe('company-123');
    });
  });
});

describe('Type guards', () => {
  describe('isUser', () => {
    test('should return true for valid User object', () => {
      const validUser: User = {
        id: 'user-123',
        email: 'test@example.com',
        full_name: 'Test User',
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z'
      };

      expect(isUser(validUser)).toBe(true);
    });

    test('should return true for User object with optional fields', () => {
      const userWithAvatar: User = {
        id: 'user-123',
        email: 'test@example.com',
        full_name: 'Test User',
        avatar_url: 'https://example.com/avatar.jpg',
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z'
      };

      expect(isUser(userWithAvatar)).toBe(true);
    });

    test('should return false for invalid objects', () => {
      const invalidObjects = [
        null,
        undefined,
        {},
        { id: 'test' }, // missing required fields
        { id: 123, email: 'test@example.com' }, // wrong type for id
        'not an object',
        []
      ];

      invalidObjects.forEach(obj => {
        expect(isUser(obj)).toBe(false);
      });
    });
  });

  describe('isOrganization', () => {
    test('should return true for valid Organization object', () => {
      const validOrg: Organization = {
        id: 'org-123',
        name: 'Test Organization',
        slug: 'test-org',
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z'
      };

      expect(isOrganization(validOrg)).toBe(true);
    });

    test('should return true for Organization with settings', () => {
      const orgWithSettings: Organization = {
        id: 'org-123',
        name: 'Test Organization',
        slug: 'test-org',
        settings: { theme: 'dark', notifications: true },
        created_at: '2025-01-01T00:00:00Z',
        updated_at: '2025-01-01T00:00:00Z'
      };

      expect(isOrganization(orgWithSettings)).toBe(true);
    });

    test('should return false for invalid objects', () => {
      const invalidObjects = [
        null,
        undefined,
        {},
        { id: 'test' }, // missing required fields
        { id: 123, name: 'Test' }, // wrong type for id
        'not an object',
        []
      ];

      invalidObjects.forEach(obj => {
        expect(isOrganization(obj)).toBe(false);
      });
    });
  });
}); 