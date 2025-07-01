/**
 * Jest setup file for VibeBiz SaaS Template
 * This file runs before each test file in the entire test suite
 */

// Global test timeout (30 seconds for async operations)
jest.setTimeout(30000);

// Mock console methods in tests to reduce noise
const originalError = console.error;
const originalWarn = console.warn;

beforeAll(() => {
  console.error = (...args) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning: ReactDOM.render is deprecated')
    ) {
      return;
    }
    originalError.call(console, ...args);
  };

  console.warn = (...args) => {
    if (typeof args[0] === 'string' && args[0].includes('Warning: ')) {
      return;
    }
    originalWarn.call(console, ...args);
  };
});

afterAll(() => {
  console.error = originalError;
  console.warn = originalWarn;
});

// Global test utilities
global.testUtils = {
  // Generate test data
  createMockUser: (overrides = {}) => ({
    id: 'test-user-id',
    email: 'test@example.com',
    full_name: 'Test User',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  }),

  createMockOrganization: (overrides = {}) => ({
    id: 'test-org-id',
    name: 'Test Organization',
    slug: 'test-org',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  }),

  // Mock API responses
  mockApiResponse: (data, status = 200) => ({
    status,
    data,
    headers: {
      'content-type': 'application/json',
    },
  }),

  // Wait for async operations
  waitFor: (ms = 100) => new Promise((resolve) => setTimeout(resolve, ms)),
};

// Environment variables for testing - use environment defaults or generate secure values
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.TEST_DATABASE_URL ||
  'postgresql://postgres:postgres@localhost:5432/vibebiz_test';
process.env.JWT_SECRET =
  process.env.TEST_JWT_SECRET ||
  'test-jwt-secret-' + Math.random().toString(36).substring(2, 15);
process.env.REDIS_URL = process.env.TEST_REDIS_URL || 'redis://localhost:6379/1';

// Suppress specific warnings in tests
const originalConsoleWarn = console.warn;
console.warn = (...args) => {
  const message = args[0];
  if (
    typeof message === 'string' &&
    (message.includes('componentWillMount has been renamed') ||
      message.includes('componentWillReceiveProps has been renamed') ||
      message.includes('React.createFactory() is deprecated'))
  ) {
    return;
  }
  originalConsoleWarn.apply(console, args);
};
