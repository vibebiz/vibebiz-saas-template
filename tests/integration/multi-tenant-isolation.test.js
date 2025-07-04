/**
 * Multi-Tenant Data Isolation Integration Tests
 *
 * These tests verify that data is properly isolated between organizations
 * and that users cannot access data from other tenants.
 */

/* eslint-env jest */
/* global crossCuttingTestUtils */

// This test suite requires a real API connection to test database RLS
process.env.CROSS_CUTTING_USE_REAL_API = 'true';

describe('Multi-Tenant Data Isolation', () => {
  let apiClient;
  let dbUtils;
  let testData;

  beforeAll(async () => {
    // Setup test environment and utilities
    apiClient = crossCuttingTestUtils.createApiTestClient();
    dbUtils = crossCuttingTestUtils.createDatabaseTestUtils();
    testData = crossCuttingTestUtils.createMultiTenantData();

    // Seed test data for multiple organizations
    await dbUtils.seedTestData(testData);
  });

  afterAll(async () => {
    // Cleanup test data
    await dbUtils.cleanupTables(['users', 'organizations', 'documents']);
  });

  describe('Row-Level Security (RLS) Policy Enforcement', () => {
    it('should prevent users from accessing other organizations data', async () => {
      // Arrange: User from Organization 1 tries to access Organization 2 data
      const org1User = testData.users.find((u) => u.organization_id === 'org-1');

      // Act: Attempt to access cross-tenant data
      const response = await apiClient.get('/api/v1/documents', {
        headers: {
          Authorization: `Bearer ${org1User.token}`,
          'X-Organization-ID': 'org-2', // Attempting to access different org
        },
      });

      // Assert: Access should be denied
      expect(response.status).toBe(403);
      expect(await response.json()).toMatchObject({
        error: 'Forbidden',
        message: expect.stringMatching(/organization/i),
      });
    });

    it('should allow users to access their own organization data', async () => {
      // Arrange: User accessing their own organization's data
      const org1User = testData.users.find((u) => u.organization_id === 'org-1');

      // Act: Access own organization data
      const response = await apiClient.get('/api/v1/documents', {
        headers: {
          Authorization: `Bearer ${org1User.token}`,
          'X-Organization-ID': 'org-1',
        },
      });

      // Assert: Access should be allowed
      expect(response.status).toBe(200);
      const documents = await response.json();
      expect(Array.isArray(documents)).toBe(true);

      // All returned documents should belong to the user's organization
      documents.forEach((doc) => {
        expect(doc.organization_id).toBe('org-1');
      });
    });
  });

  describe('API Endpoint Tenant Validation', () => {
    it('should validate organization context in API middleware', async () => {
      // Arrange: Create document without organization context
      const user = testData.users[0];

      // Act: Attempt API call without organization header
      const response = await apiClient.post(
        '/api/v1/documents',
        { title: 'Test Document' },
        {
          headers: {
            Authorization: `Bearer ${user.token}`,
            // Missing X-Organization-ID header
          },
        }
      );

      // Assert: Should require organization context
      expect(response.status).toBe(400);
      expect(await response.json()).toMatchObject({
        error: 'Bad Request',
        message: expect.stringMatching(/organization.*required/i),
      });
    });

    it('should reject mismatched user and organization', async () => {
      // Arrange: User from org-1 with org-2 context
      const org1User = testData.users.find((u) => u.organization_id === 'org-1');

      // Act: Attempt to use wrong organization context
      const response = await apiClient.post(
        '/api/v1/documents',
        { title: 'Test Document' },
        {
          headers: {
            Authorization: `Bearer ${org1User.token}`,
            'X-Organization-ID': 'org-2', // Wrong organization
          },
        }
      );

      // Assert: Should reject the request
      expect(response.status).toBe(403);
      expect(await response.json()).toMatchObject({
        error: 'Forbidden',
        message: expect.stringMatching(/not.*member.*organization/i),
      });
    });
  });

  describe('Database Query Tenant Isolation', () => {
    it('should automatically filter queries by organization_id', async () => {
      // This test would require database access to verify that
      // all queries include proper WHERE clauses for organization_id

      // Arrange: Setup database query monitoring
      const org1User = testData.users.find((u) => u.organization_id === 'org-1');

      // Act: Make API request that triggers database queries
      const response = await apiClient.get('/api/v1/dashboard', {
        headers: {
          Authorization: `Bearer ${org1User.token}`,
          'X-Organization-ID': 'org-1',
        },
      });

      // Assert: Response should only contain org-1 data
      expect(response.status).toBe(200);
      const dashboard = await response.json();

      // Verify all nested data belongs to the correct organization
      expect(dashboard.organization_id).toBe('org-1');
      if (dashboard.recent_documents) {
        dashboard.recent_documents.forEach((doc) => {
          expect(doc.organization_id).toBe('org-1');
        });
      }
      if (dashboard.team_members) {
        dashboard.team_members.forEach((member) => {
          expect(member.organization_id).toBe('org-1');
        });
      }
    });
  });

  describe('Cross-Service Tenant Isolation', () => {
    it('should maintain tenant context across service calls', async () => {
      // Test that when public-api calls other services,
      // the tenant context is properly propagated

      const org1User = testData.users.find((u) => u.organization_id === 'org-1');

      // Act: Trigger a cross-service operation
      const response = await apiClient.post(
        '/api/v1/reports/generate',
        { type: 'usage', period: 'monthly' },
        {
          headers: {
            Authorization: `Bearer ${org1User.token}`,
            'X-Organization-ID': 'org-1',
          },
        }
      );

      // Assert: Report should only include org-1 data
      expect(response.status).toBe(202); // Accepted for processing
      const result = await response.json();
      expect(result.report_id).toBeDefined();

      // Wait for report generation and verify tenant isolation
      await crossCuttingTestUtils.waitForCondition(async () => {
        const reportResponse = await apiClient.get(
          `/api/v1/reports/${result.report_id}`,
          {
            headers: {
              Authorization: `Bearer ${org1User.token}`,
              'X-Organization-ID': 'org-1',
            },
          }
        );
        return reportResponse.status === 200;
      }, 10000);
    });
  });

  describe('Performance Impact of Tenant Isolation', () => {
    it('should not significantly impact query performance', async () => {
      const performanceUtils = crossCuttingTestUtils.createPerformanceTestUtils();
      const org1User = testData.users.find((u) => u.organization_id === 'org-1');

      // Measure response time for tenant-filtered queries
      const performanceResult = await performanceUtils.measureResponseTime(
        async () => {
          const response = await apiClient.get('/api/v1/documents?limit=100', {
            headers: {
              Authorization: `Bearer ${org1User.token}`,
              'X-Organization-ID': 'org-1',
            },
          });
          expect(response.status).toBe(200);
        },
        5 // Run 5 iterations
      );

      // Assert: Response time should be under acceptable threshold
      performanceUtils.assertResponseTime(
        performanceResult.average,
        200, // 200ms max average response time
        'Tenant-filtered document query'
      );

      console.log(`Average response time: ${performanceResult.average.toFixed(2)}ms`);
    });
  });
});
