/**
 * Shared types for VibeBiz SaaS Template
 */

// User types
export interface User {
  id: string;
  email: string;
  full_name: string;
  avatar_url?: string;
  created_at: string;
  updated_at: string;
}

export interface CreateUserRequest {
  email: string;
  password: string;
  full_name: string;
}

// Organization types
export interface Organization {
  id: string;
  name: string;
  slug: string;
  settings?: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface CreateOrganizationRequest {
  name: string;
  slug?: string;
}

// API Response types
export interface ApiResponse<T = any> {
  data: T;
  message?: string;
  status: number;
}

export interface PaginatedResponse<T = any> {
  data: T[];
  pagination: {
    page: number;
    page_size: number;
    total: number;
    total_pages: number;
  };
}

export interface ApiError {
  message: string;
  code: string;
  details?: Record<string, any>;
}

// Utility types
export type Status = 'active' | 'inactive' | 'pending' | 'deleted';

export type UserRole = 'owner' | 'admin' | 'member' | 'viewer';

// Type guards and utility functions
export function isValidEmail(email: string): boolean {
  // Basic validation: must have @ and at least one dot in domain
  if (!email || !email.includes('@') || email.includes(' ')) {
    return false;
  }
  
  const parts = email.split('@');
  if (parts.length !== 2) {
    return false;
  }
  
  const [localPart, domain] = parts;
  
  // Local part validation
  if (!localPart || localPart.length === 0 || localPart.includes('..')) {
    return false;
  }
  
  // Domain validation - must have at least one dot and proper structure
  if (!domain || !domain.includes('.') || domain.startsWith('.') || domain.endsWith('.')) {
    return false;
  }
  
  const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
  return emailRegex.test(email) && email.length <= 320; // RFC 5321 limit
}

export function createSlug(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

export function isUser(obj: any): obj is User {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    typeof obj.id === 'string' &&
    typeof obj.email === 'string' &&
    typeof obj.full_name === 'string' &&
    typeof obj.created_at === 'string' &&
    typeof obj.updated_at === 'string'
  );
}

export function isOrganization(obj: any): obj is Organization {
  return (
    typeof obj === 'object' &&
    obj !== null &&
    typeof obj.id === 'string' &&
    typeof obj.name === 'string' &&
    typeof obj.slug === 'string' &&
    typeof obj.created_at === 'string' &&
    typeof obj.updated_at === 'string'
  );
} 