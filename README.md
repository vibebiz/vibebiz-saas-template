# VibeBiz SaaS Template

A comprehensive, progressive SaaS template system for rapid development and
deployment of multi-tenant applications.

## Local Development Setup

This project uses a suite of pre-commit hooks to enforce code quality, consistency,
and security.

### Prerequisites

- **Node.js & pnpm**: Install Node.js (v18+) and pnpm (`npm install -g pnpm`).
- **Python**: Install Python (v3.10+).
- **Homebrew** (macOS/Linux): Required for some tools like Spectral.

### Setting Up Pre-Commit Hooks

1. **Install Dependencies**:

   ```bash
   pnpm install
   ```

2. **Install `pre-commit`**:

   ```bash
   pip install pre-commit
   ```

3. **Install Git Hooks**:

   ```bash
   pre-commit install --hook-type commit-msg --hook-type pre-commit
   ```

4. **Configure Spectral**: The API specification linter (`spectral`) requires a DSN
   key to run scans. Please follow the instructions in our guide to set it up:
   - **[How to Set Up Spectral](./docs/spectral-setup.md)**

### Running All Checks

You can manually trigger all checks on all files at any time:

```bash
pnpm all-checks
```

---

## 🧪 Unit Testing Framework

This template includes a comprehensive unit testing framework that supports both
TypeScript (Jest) and Python (pytest) testing across the monorepo.

### Quick Start

```bash
# Install dependencies
pnpm install

# Run all tests across the monorepo
pnpm test

# Run tests with coverage reporting
pnpm test:coverage

# Run only unit tests
pnpm test:unit
```

## Testing Architecture

### Configuration Overview

- **Root Configuration**: `jest.config.js` and `pytest.ini` for monorepo-wide settings
- **Package-Specific**: Each package has its own testing configuration
- **Coverage Threshold**: Minimum 60% coverage required (MVP standard)
- **Orchestration**: Turborepo coordinates test execution across packages

### Directory Structure

```text
vibebiz-saas-template/
├── jest.config.js              # Root Jest configuration
├── jest.setup.js               # Global Jest setup
├── pytest.ini                  # Root pytest configuration
├── turbo.json                  # Turborepo orchestration
├── apps/
│   └── public-web/             # Next.js app
│       ├── jest.setup.js       # App-specific Jest setup
│       ├── __tests__/          # Component tests
│       └── src/components/     # Components under test
├── services/
│   └── public-api/             # Python FastAPI service
│       ├── pyproject.toml      # Python dependencies & pytest config
│       ├── tests/              # Python unit tests
│       └── src/                # Python source code
└── packages/
    └── types/                  # Shared TypeScript package
        ├── __tests__/          # TypeScript unit tests
        └── src/                # TypeScript source code
```

## TypeScript Testing (Jest)

### Jest Features

- **Jest** with `ts-jest` for TypeScript support
- **React Testing Library** for component testing
- **60% coverage threshold** (configurable per package)
- **Global test utilities** for mocking and data generation
- **Next.js mocking** for router and navigation

### Example TypeScript Test

```typescript
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from '../src/components/Button';

test('calls onClick when clicked', async () => {
  const handleClick = jest.fn();
  const user = userEvent.setup();

  render(<Button onClick={handleClick}>Click me</Button>);

  const button = screen.getByRole('button');
  await user.click(button);

  expect(handleClick).toHaveBeenCalledTimes(1);
});
```

### Running TypeScript Tests

```bash
# Run tests for a specific package
cd packages/types
pnpm test

# Run tests with coverage
pnpm test:coverage

# Watch mode for development
pnpm test:watch
```

## Python Testing (pytest)

### Pytest Features

- **pytest** with async support (`pytest-asyncio`)
- **Coverage reporting** with `pytest-cov`
- **60% coverage threshold** enforced
- **Test markers** for organizing test types (unit, integration, api, etc.)
- **Factory Boy** for test data generation

### Test Markers

```python
@pytest.mark.unit        # Fast, isolated unit tests
@pytest.mark.integration # Integration tests with external dependencies
@pytest.mark.slow        # Slower running tests
@pytest.mark.api         # API endpoint tests
@pytest.mark.auth        # Authentication tests
```

### Example Python Test

```python
def test_generate_secure_token():
    """Test secure token generation"""
    token = generate_secure_token(length=32)

    assert len(token) == 32
    assert isinstance(token, str)

    # Test uniqueness
    tokens = [generate_secure_token() for _ in range(100)]
    assert len(set(tokens)) == 100
```

### Running Python Tests

```bash
# Run tests for a specific service
cd services/public-api
pytest

# Run with coverage
pytest --cov=src

# Run specific test markers
pytest -m unit  # Only unit tests
pytest -m "not slow"  # Exclude slow tests
```

## Global Test Utilities

The testing framework provides global utilities available in all tests:

### JavaScript/TypeScript Utilities

```typescript
// Available in all Jest tests via global.testUtils
testUtils.createMockUser({ email: 'custom@example.com' });
testUtils.createMockOrganization({ name: 'Custom Org' });
testUtils.mockApiResponse({ data: 'test' }, 200);
testUtils.waitFor(100); // Async delay
```

### Python Test Fixtures

```python
# Use pytest fixtures for common test data
def test_example(mock_user, mock_organization):
    # mock_user and mock_organization are available fixtures
    assert mock_user.email == 'test@example.com'
```

## Coverage Requirements

### Minimum Thresholds (MVP)

- **Lines**: 60%
- **Functions**: 60%
- **Branches**: 60%
- **Statements**: 60%

### Coverage Reports

```bash
# Generate HTML coverage reports
pnpm test:coverage

# View TypeScript coverage
open packages/types/coverage/index.html

# View Python coverage
open services/public-api/htmlcov/index.html
```

## CI/CD Integration

The testing framework is designed for CI/CD pipelines:

### Turborepo Orchestration

```json
{
  "pipeline": {
    "test": {
      "dependsOn": ["^build"],
      "outputs": ["coverage/**", ".coverage"]
    }
  }
}
```

### GitHub Actions Ready

Tests output in formats compatible with GitHub Actions:

- **Jest**: JSON and LCOV coverage reports
- **pytest**: XML and JSON coverage reports
- **JUnit**: XML test results for CI parsing

## Best Practices

### Test Organization

1. **Co-locate tests** with source code where possible
2. **Use descriptive test names** that explain the behavior
3. **Group related tests** using `describe` blocks (Jest) or classes (pytest)
4. **Test both happy path and edge cases**
5. **Mock external dependencies** in unit tests

### Writing Quality Tests

```typescript
// ✅ Good: Descriptive, focused test
test('should return validation error for invalid email format', () => {
  expect(isValidEmail('invalid-email')).toBe(false);
});

// ❌ Bad: Vague test name
test('email test', () => {
  expect(isValidEmail('test')).toBe(false);
});
```

### Mocking Guidelines

1. **Mock external APIs** and services
2. **Use real implementations** for internal utilities
3. **Provide realistic mock data**
4. **Reset mocks** between tests

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure dependencies are installed (`pnpm install`)
2. **Coverage Failures**: Check that new code includes tests
3. **Async Test Issues**: Use `async/await` properly in tests
4. **Mock Problems**: Verify mocks are reset between tests

### Debug Mode

```bash
# Run Jest in debug mode
node --inspect-brk node_modules/.bin/jest --runInBand

# Run pytest with detailed output
pytest -vv --tb=long
```

## Contributing

When adding new packages or services:

1. **Copy testing configuration** from existing packages
2. **Update `turbo.json`** to include new test targets
3. **Maintain coverage thresholds**
4. **Add appropriate test markers** for Python tests

---

## Next Steps

- Install dependencies: `pnpm install`
- Run the test suite: `pnpm test`
- Explore the sample tests in `packages/types` and `services/public-api`
- Add your own packages following the established patterns

For more information, see the [VibeBiz Documentation](https://docs.vibebiz.dev).
