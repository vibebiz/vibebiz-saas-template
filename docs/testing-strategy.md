# VibeBiz Testing Strategy

## Overview

VibeBiz uses a **hybrid testing approach** that balances fast development feedback with comprehensive system validation. This strategy follows the principle of "fail fast, validate thoroughly."

## Testing Tiers

### 🚀 Fast Feedback (Local Development)

**Purpose**: Quick validation during development
**When to run**: During coding, before commits, local development
**Tools**: Pre-commit hooks, `./tools/run-all-checks.sh`

**Includes**:

- Code quality checks (ESLint, Prettier, Ruff)
- Security scanning (Semgrep, Bandit, Gitleaks)
- Unit tests (package-local)
- Integration tests (package-local)
- Type checking
- Dependency security audits

**Excludes**:

- E2E tests (require running servers)
- Cross-cutting tests (comprehensive system validation)
- Performance tests
- Accessibility tests

### 🔍 Comprehensive Validation (CI/CD)

**Purpose**: Full system validation before deployment
**When to run**: CI/CD pipeline, pre-deployment, release validation
**Tools**: `./tools/run-comprehensive-tests.sh`, `pnpm test:comprehensive`

**Includes**:

- All fast feedback checks
- E2E tests (with proper infrastructure)
- Cross-cutting integration tests
- Security vulnerability tests
- Performance tests
- Accessibility tests (WCAG 2.2 AA)

## Why This Approach?

### Problem with E2E Tests in Pre-commit

1. **Server Dependencies**: E2E tests require running web servers
2. **Startup Time**: Server startup can take 1-3 minutes
3. **Resource Usage**: Heavy on CPU/memory during development
4. **Flaky Behavior**: Network issues, port conflicts, dependency problems
5. **Developer Experience**: Slow feedback loop kills productivity

### Benefits of Hybrid Approach

1. **Fast Feedback**: Developers get quick validation (seconds vs minutes)
2. **Comprehensive Coverage**: Full validation happens in CI/CD
3. **Better Infrastructure**: CI/CD environments are more stable for E2E tests
4. **Parallel Execution**: CI/CD can run tests in parallel with proper resources
5. **Monitoring**: Better visibility into test failures and performance

## Usage Guide

### For Developers

```bash
# Daily development workflow
pnpm test                    # Package-local tests only
./tools/run-all-checks.sh    # Fast feedback (pre-commit style)

# When you need comprehensive validation
pnpm test:comprehensive      # Full test suite (may take 10-15 minutes)
```

### For CI/CD

```yaml
# Example GitHub Actions workflow
jobs:
  fast-feedback:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: ./tools/run-all-checks.sh

  comprehensive-tests:
    runs-on: ubuntu-latest
    needs: fast-feedback
    steps:
      - uses: actions/checkout@v4
      - run: ./tools/run-comprehensive-tests.sh
```

## Test Commands Reference

| Command                              | Purpose             | When to Use            |
| ------------------------------------ | ------------------- | ---------------------- |
| `pnpm test`                          | Package-local tests | Daily development      |
| `pnpm test:unit`                     | Unit tests only     | Quick validation       |
| `pnpm test:integration`              | Integration tests   | Service testing        |
| `pnpm test:e2e`                      | E2E tests only      | UI workflow testing    |
| `pnpm test:accessibility`            | Accessibility tests | WCAG compliance        |
| `pnpm test:security`                 | Security tests      | Vulnerability scanning |
| `pnpm test:performance`              | Performance tests   | Load testing           |
| `pnpm test:comprehensive`            | All tests           | Pre-deployment         |
| `./tools/run-all-checks.sh`          | Fast feedback       | Local development      |
| `./tools/run-comprehensive-tests.sh` | Full validation     | CI/CD                  |

## E2E Test Infrastructure

### Server Startup

E2E tests use Playwright's `webServer` configuration:

- **Command**: `pnpm --filter @vibebiz/public-web dev`
- **Health Check**: `http://localhost:3000/api/health`
- **Timeout**: 3 minutes for startup
- **Retries**: 30 attempts with 2-second intervals

### Health Check Endpoint

The public-web app includes a health check at `/api/health`:

```json
{
  "status": "healthy",
  "timestamp": "2025-01-01T00:00:00.000Z",
  "service": "public-web",
  "version": "1.0.0"
}
```

## Best Practices

### For Developers

1. **Run fast feedback tests frequently** during development
2. **Don't commit without passing fast feedback tests**
3. **Use comprehensive tests before major changes**
4. **Fix flaky tests immediately** - they indicate real problems

### For CI/CD

1. **Always run comprehensive tests before deployment**
2. **Monitor test execution times** and optimize slow tests
3. **Set up alerts for test failures**
4. **Maintain test infrastructure** (databases, services)

### For Test Maintenance

1. **Keep unit tests fast** (< 100ms per test)
2. **Mock external dependencies** in unit tests
3. **Use real infrastructure** for integration tests
4. **Test user workflows** in E2E tests, not implementation details

## Troubleshooting

### E2E Tests Hanging

1. **Check server startup**: Look for port conflicts or dependency issues
2. **Verify health check**: Ensure `/api/health` endpoint is working
3. **Check logs**: Review server stdout/stderr for errors
4. **Increase timeouts**: Adjust `webServer.timeout` if needed

### Slow Test Execution

1. **Run tests in parallel**: Use `fullyParallel: true`
2. **Optimize test data**: Use factories instead of database seeding
3. **Mock heavy operations**: Avoid real external API calls
4. **Use test isolation**: Clean up data between tests

## Migration from Old Approach

If you're migrating from running E2E tests in pre-commit:

1. **Update pre-commit config**: Remove E2E test hooks
2. **Update CI/CD**: Add comprehensive test stage
3. **Update documentation**: Explain new testing strategy
4. **Train team**: Ensure everyone understands the workflow

## Future Improvements

1. **Test parallelization**: Run tests across multiple containers
2. **Test data management**: Implement better test data factories
3. **Performance monitoring**: Track test execution times
4. **Visual regression**: Add visual testing for UI components
5. **Contract testing**: Implement API contract testing

---

**Remember**: Fast feedback enables rapid development, while comprehensive validation ensures quality. Both are essential for a successful testing strategy.
