/**
 * Jest setup file for Cross-Cutting Tests
 * This file runs before each test file in the cross-cutting test suite
 */

// Extended timeout for integration tests
jest.setTimeout(60000);

// Cross-cutting test utilities
global.crossCuttingTestUtils = {
  // Multi-tenant test data
  createMultiTenantData: () => ({
    organizations: [
      {
        id: 'org-1',
        name: 'Organization One',
        slug: 'org-one',
        domain: 'org1.example.com',
      },
      {
        id: 'org-2',
        name: 'Organization Two',
        slug: 'org-two',
        domain: 'org2.example.com',
      },
    ],
    users: [
      {
        id: 'user-1',
        email: 'user1@org1.example.com',
        organization_id: 'org-1',
        role: 'admin',
      },
      {
        id: 'user-2',
        email: 'user2@org2.example.com',
        organization_id: 'org-2',
        role: 'user',
      },
    ],
  }),

  // API test utilities
  createApiTestClient: (baseURL = 'http://localhost:8000') => {
    return {
      get: (path, options = {}) =>
        fetch(`${baseURL}${path}`, { method: 'GET', ...options }),
      post: (path, data, options = {}) =>
        fetch(`${baseURL}${path}`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
          ...options,
        }),
      put: (path, data, options = {}) =>
        fetch(`${baseURL}${path}`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data),
          ...options,
        }),
      delete: (path, options = {}) =>
        fetch(`${baseURL}${path}`, { method: 'DELETE', ...options }),
    };
  },

  // Database test utilities
  createDatabaseTestUtils: () => ({
    cleanupTables: async (tables = []) => {
      // Implementation would depend on your database setup
      // This is a placeholder for database cleanup
      console.log(`Cleaning up tables: ${tables.join(', ')}`);
    },

    seedTestData: async (data) => {
      // Implementation would depend on your database setup
      // This is a placeholder for data seeding
      console.log('Seeding test data:', Object.keys(data));
    },
  }),

  // Performance test utilities
  createPerformanceTestUtils: () => ({
    measureResponseTime: async (fn, iterations = 10) => {
      const times = [];
      for (let i = 0; i < iterations; i++) {
        const start = performance.now();
        await fn();
        const end = performance.now();
        times.push(end - start);
      }
      return {
        average: times.reduce((a, b) => a + b, 0) / times.length,
        min: Math.min(...times),
        max: Math.max(...times),
        times,
      };
    },

    assertResponseTime: (actualTime, maxTime, message) => {
      if (actualTime > maxTime) {
        throw new Error(
          `${message}: Expected response time to be under ${maxTime}ms, but was ${actualTime}ms`
        );
      }
    },
  }),

  // Security test utilities
  createSecurityTestUtils: () => ({
    generateMaliciousInputs: () => [
      '<script>alert("xss")</script>',
      "'; DROP TABLE users; --",
      '../../../etc/passwd',
      'javascript:alert("xss")',
      '{{constructor.constructor("alert(1)")()}}',
    ],

    testSqlInjection: async (apiClient, endpoint, payload) => {
      const maliciousInputs = [
        "' OR '1'='1",
        "'; DROP TABLE users; --",
        "' UNION SELECT * FROM users --",
      ];

      const results = [];
      for (const input of maliciousInputs) {
        try {
          const response = await apiClient.post(endpoint, { ...payload, input });
          results.push({
            input,
            status: response.status,
            blocked: response.status >= 400,
          });
        } catch (error) {
          results.push({
            input,
            error: error.message,
            blocked: true,
          });
        }
      }
      return results;
    },
  }),

  // Wait utilities for async operations
  waitForCondition: async (conditionFn, timeout = 30000, interval = 100) => {
    const start = Date.now();
    while (Date.now() - start < timeout) {
      if (await conditionFn()) {
        return true;
      }
      await new Promise((resolve) => setTimeout(resolve, interval));
    }
    throw new Error(`Condition not met within ${timeout}ms`);
  },

  // Retry utilities for flaky tests
  retryAsync: async (fn, maxRetries = 3, delay = 1000) => {
    let lastError;
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (error) {
        lastError = error;
        if (i < maxRetries - 1) {
          await new Promise((resolve) => setTimeout(resolve, delay));
        }
      }
    }
    throw lastError;
  },
};

// Environment variables for cross-cutting tests
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL =
  process.env.DATABASE_URL ||
  'postgresql://test:test@localhost:5432/vibebiz_integration_test';
process.env.REDIS_URL = process.env.REDIS_URL || 'redis://localhost:6379/2';
process.env.API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:8000';

// Global test hooks
beforeAll(async () => {
  // Setup shared test environment
  console.log('Setting up cross-cutting test environment...');
});

afterAll(async () => {
  // Cleanup shared test environment
  console.log('Cleaning up cross-cutting test environment...');
});

beforeEach(async () => {
  // Reset shared state before each test
});

afterEach(async () => {
  // Cleanup after each test
});
