# Testing Framework Integration Guide

This document explains how the centralized `/tests` directory integrates with the existing package-local testing framework.

## Testing Architecture: Hybrid Approach

VibeBiz uses a **hybrid testing strategy** that combines:

1. **Package-local tests** (existing) - Unit and component tests
2. **Cross-cutting tests** (new) - System-wide integration and E2E tests

## Test Distribution Strategy

### 📦 Package-Local Tests (Keep Current Structure)

**Location**: Within each package/service directory
**Purpose**: Fast, isolated testing of individual components/modules

```
apps/public-web/
├── __tests__/          # Component unit tests
├── e2e/               # App-specific E2E tests
└── src/

services/public-api/
├── tests/             # API unit & integration tests
└── src/

packages/types/
├── __tests__/         # Type definition tests
└── src/
```

**What to test here:**

- ✅ Component behavior and props
- ✅ Individual API endpoint functionality
- ✅ Business logic and utility functions
- ✅ Database models and validation
- ✅ Single-service integration tests

### 🌐 Cross-Cutting Tests (New Centralized Structure)

**Location**: `/tests` directory
**Purpose**: System-wide testing that spans multiple services/packages

```
tests/
├── e2e/user-flows/     # Complete user journeys
├── integration/        # Multi-service integration
├── performance/        # Load and stress testing
├── security/          # Penetration and vulnerability tests
├── accessibility/     # System-wide a11y compliance
└── fixtures/          # Shared test data
```

**What to test here:**

- ✅ Complete user workflows (login → dashboard → actions)
- ✅ Multi-tenant data isolation across services
- ✅ Cross-service communication and data flow
- ✅ System performance under load
- ✅ Security vulnerabilities and compliance
- ✅ Full accessibility compliance

## Integration Points

### 1. Shared Test Data and Fixtures

```bash
# Package-local tests use local fixtures
apps/public-web/__tests__/fixtures/

# Cross-cutting tests use shared fixtures
tests/fixtures/
├── users.json          # Shared user test data
├── organizations.json  # Multi-tenant test data
└── api-responses.json  # Shared API mock data
```

### 2. Test Command Integration

Update package.json scripts to coordinate both test types:

```json
{
  "scripts": {
    "test": "turbo run test", // Package-local tests
    "test:integration": "jest tests/integration", // Cross-cutting integration
    "test:e2e": "playwright test tests/e2e", // Cross-cutting E2E
    "test:performance": "k6 run tests/performance/",
    "test:security": "npm run test:security --prefix tests/",
    "test:all": "npm run test && npm run test:integration && npm run test:e2e"
  }
}
```

### 3. CI/CD Pipeline Integration

```yaml
# .github/workflows/test.yml
jobs:
  unit-tests:
    name: Package Unit Tests
    steps:
      - run: pnpm test # Runs package-local tests

  integration-tests:
    name: Cross-Cutting Tests
    needs: unit-tests
    steps:
      - run: pnpm test:integration
      - run: pnpm test:e2e
      - run: pnpm test:performance
```

## Configuration Coordination

### Jest Configuration

```javascript
// jest.config.js (root)
module.exports = {
  projects: [
    // Package-local test configs
    '<rootDir>/apps/*/jest.config.js',
    '<rootDir>/packages/*/jest.config.js',
    // Cross-cutting test config
    '<rootDir>/tests/jest.config.js',
  ],
};
```

### Environment Management

```bash
# Package-local tests - isolated environments
DATABASE_URL=sqlite:///:memory:
API_URL=http://localhost:3001

# Cross-cutting tests - shared test environment
DATABASE_URL=postgresql://test:test@localhost:5432/integration_test
API_URL=http://localhost:8000
REDIS_URL=redis://localhost:6379/1
```

## Best Practices

### When to Use Package-Local Tests

- ✅ Testing individual component logic
- ✅ API endpoint validation
- ✅ Database model behavior
- ✅ Utility function correctness
- ✅ Quick feedback during development

### When to Use Cross-Cutting Tests

- ✅ User journey validation
- ✅ Multi-service data flow
- ✅ Performance bottleneck identification
- ✅ Security vulnerability detection
- ✅ Compliance verification (WCAG, SOC2)
- ✅ Multi-tenant isolation verification

### Coverage Strategy

```
Package-local tests:  80% coverage minimum
Cross-cutting tests:  100% critical path coverage
Security tests:       100% auth/authorization coverage
Performance tests:    SLA compliance verification
```

## Migration Strategy

### Phase 1: Keep Current Structure (✅ Done)

- Maintain existing package-local tests
- Continue using current CI/CD pipeline
- No breaking changes to development workflow

### Phase 2: Add Cross-Cutting Tests (🔄 In Progress)

- Implement critical user journey E2E tests
- Add multi-tenant integration tests
- Set up performance monitoring
- Add security vulnerability scanning

### Phase 3: Optimize and Scale (📋 Future)

- Optimize test execution time
- Add visual regression testing
- Implement chaos engineering tests
- Scale performance testing for production loads

## Developer Workflow

### During Development

```bash
# Fast feedback loop - run package-local tests
cd apps/public-web
pnpm test:watch

# Pre-commit - run relevant cross-cutting tests
pnpm test:integration:auth  # If working on auth features
```

### Before Merge

```bash
# Complete test suite
pnpm test:all
```

### Pre-deployment

```bash
# Full system validation
pnpm test:e2e
pnpm test:performance
pnpm test:security
```

## Monitoring and Reporting

### Test Metrics

- Package-local test coverage: Minimum 80%
- Cross-cutting test coverage: 100% critical paths
- E2E test success rate: 99%+
- Performance test SLA compliance: 100%

### Reporting Integration

- Jest reports: HTML, LCOV, JSON
- Playwright reports: HTML with traces
- Performance reports: K6 dashboard
- Security reports: OWASP ZAP, GitHub Security

This hybrid approach provides the best of both worlds: fast developer feedback through package-local tests and comprehensive system validation through cross-cutting tests.
