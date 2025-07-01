import type { ReactNode } from 'react';

interface MockApiResponse {
  ok: boolean;
  status: number;
  json: () => Promise<unknown>;
  text: () => Promise<string>;
}

// Mock API responses
export const mockApiCall = (data: unknown, status = 200): Promise<MockApiResponse> =>
  Promise.resolve({
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.resolve(data),
    text: () => Promise.resolve(JSON.stringify(data)),
  });

// Create mock component props
export const createMockProps = (overrides: Record<string, unknown> = {}) => ({
  className: '',
  children: null as ReactNode,
  ...overrides,
});

// Mock user data
export const createMockUser = (overrides: Record<string, unknown> = {}) => ({
  id: 'user-123',
  email: 'test@example.com',
  full_name: 'Test User',
  avatar_url: 'https://example.com/avatar.jpg',
  ...overrides,
});

// Mock organization data
export const createMockOrganization = (overrides: Record<string, unknown> = {}) => ({
  id: 'org-123',
  name: 'Test Organization',
  slug: 'test-org',
  ...overrides,
});
