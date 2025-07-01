# Cross-Cutting Tests

This directory contains system-wide tests that span multiple packages and services in the VibeBiz SaaS template.

## Structure

```
tests/
├── e2e/                # End-to-end tests
│   ├── user-flows/     # Complete user journey tests
│   ├── api/           # Cross-service API tests
│   └── mobile/        # Mobile app E2E tests
├── integration/        # Multi-service integration tests
│   ├── auth-flow/     # Authentication integration
│   ├── payment-flow/  # Payment processing tests
│   └── tenant-isolation/ # Multi-tenant data isolation
├── performance/        # Load and performance tests
│   ├── load/          # Load testing scenarios
│   ├── stress/        # Stress testing
│   └── benchmarks/    # Performance benchmarks
├── security/          # Security testing
│   ├── penetration/   # Penetration tests
│   ├── vulnerability/ # Vulnerability scans
│   └── compliance/    # Compliance validation
├── accessibility/     # Accessibility tests
├── fixtures/          # Shared test data and fixtures
├── utils/             # Test utilities and helpers
└── config/            # Test configuration files
```

## Test Types

### End-to-End Tests

- Complete user workflows across the entire application
- Multi-tenant organization switching
- Payment and subscription flows
- Mobile app critical paths

### Integration Tests

- Cross-service communication
- Database integration with proper tenant isolation
- Authentication and authorization flows
- External service integrations (Stripe, email, etc.)

### Performance Tests

- API response time benchmarks
- Database query performance
- Frontend Core Web Vitals
- Load testing for scalability

### Security Tests

- Authentication bypass scenarios
- SQL injection prevention
- CSRF protection validation
- Rate limiting effectiveness

## Getting Started

### Prerequisites

- Node.js >= 18
- Python >= 3.11
- Docker for test environment setup

### Running Tests

```bash
# Run all cross-cutting tests
pnpm test:e2e

# Run specific test suites
pnpm test:integration
pnpm test:performance
pnpm test:security
pnpm test:accessibility

# Run tests with coverage
pnpm test:coverage
```

### Test Environment Setup

```bash
# Start test environment
docker-compose -f tests/config/docker-compose.test.yml up -d

# Run database migrations
pnpm test:setup

# Seed test data
pnpm test:seed
```

## Test Data Management

### Fixtures

- Use realistic but anonymized test data
- Maintain data consistency across test runs
- Clean up test data after each run

### Multi-Tenant Testing

- Test data isolation between organizations
- Verify Row-Level Security (RLS) policies
- Test organization switching scenarios

## Quality Gates

- All E2E tests must pass before deployment
- Performance tests must meet SLA requirements
- Security tests must pass vulnerability scans
- Accessibility tests must meet WCAG 2.2 AA standards

## CI/CD Integration

- Tests run automatically on pull requests
- Performance regression detection
- Security vulnerability blocking
- Accessibility regression prevention

## Best Practices

- Write tests from user perspective
- Use realistic test scenarios
- Mock external services appropriately
- Maintain test independence
- Document test scenarios and expected outcomes
