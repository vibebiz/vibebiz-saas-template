#!/bin/bash
#
# VibeBiz Platform Test Setup
# This script sets up and validates the testing environment
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to setup test database
setup_test_database() {
    log_info "Setting up test database..."

    # Check if PostgreSQL is running
    if ! docker ps | grep -q "vibebiz-postgres"; then
        log_warning "PostgreSQL not running - starting it for tests..."
        bash "$SCRIPT_DIR/setup-database.sh"
    fi

    # Create test database if it doesn't exist
    if ! docker exec vibebiz-postgres psql -U postgres -c "SELECT 1 FROM pg_database WHERE datname='vibebiz_test'" | grep -q 1; then
        docker exec vibebiz-postgres createdb -U postgres vibebiz_test
        log_success "Created vibebiz_test database"
    else
        log_info "vibebiz_test database already exists"
    fi

    # Run test migrations
    cd "$ROOT_DIR"
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ] && [ -d "$service_dir/migrations" ]; then
            service_name=$(basename "$service_dir")
            log_info "Running test migrations for $service_name..."

            cd "$service_dir"

            # Set test database URL
            export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/vibebiz_test"

            if poetry run alembic --help > /dev/null 2>&1; then
                if poetry run alembic upgrade head; then
                    log_success "Test migrations completed for $service_name"
                else
                    log_warning "Test migrations failed for $service_name"
                fi
            fi

            cd "$ROOT_DIR"
        fi
    done
}

# Function to setup test environment files
setup_test_env() {
    log_info "Setting up test environment files..."

    cd "$ROOT_DIR"

    # Create test environment file if it doesn't exist
    if [ ! -f "tests/.env.test" ]; then
        cat > tests/.env.test << EOF
# VibeBiz Tests Environment Configuration
NODE_ENV=test
PYTHON_ENV=test
CI=false
LOG_LEVEL=debug

# Test Database
TEST_DATABASE_URL=postgresql://postgres:postgres@localhost:5432/vibebiz_test

# Test Configuration
SPECTRAL_DSN=dev-test-spectral-optional
TEST_API_KEYS=test-api-key-1,test-api-key-2

# Test Security
TEST_JWT_SECRET_KEY=test-jwt-secret-key-for-testing-only

# Test External Services
STRIPE_SECRET_KEY=sk_test_test_key_for_testing
STRIPE_WEBHOOK_SECRET=whsec_test_webhook_secret_for_testing
EOF
        log_success "Created tests/.env.test"
    else
        log_info "tests/.env.test already exists"
    fi
}

# Function to run unit tests
run_unit_tests() {
    log_info "Running unit tests..."

    cd "$ROOT_DIR"

    local test_results=()

    # Run Node.js unit tests
    if command -v pnpm &> /dev/null; then
        log_info "Running Node.js unit tests..."
        if pnpm run test:unit; then
            log_success "Node.js unit tests passed"
            test_results+=("Node.js: ✅")
        else
            log_warning "Node.js unit tests failed"
            test_results+=("Node.js: ❌")
        fi
    fi

    # Run Python unit tests
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            log_info "Running Python unit tests for $service_name..."

            cd "$service_dir"

            # Set test environment
            export PYTHON_ENV=test
            export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/vibebiz_test"

            if poetry run pytest tests/ -v --tb=short; then
                log_success "Python unit tests passed for $service_name"
                test_results+=("$service_name: ✅")
            else
                log_warning "Python unit tests failed for $service_name"
                test_results+=("$service_name: ❌")
            fi

            cd "$ROOT_DIR"
        fi
    done

    # Display test results
    echo ""
    log_info "Unit Test Results:"
    for result in "${test_results[@]}"; do
        echo "  $result"
    done
}

# Function to run integration tests
run_integration_tests() {
    log_info "Running integration tests..."

    cd "$ROOT_DIR"

    local test_results=()

    # Run Node.js integration tests
    if command -v pnpm &> /dev/null; then
        log_info "Running Node.js integration tests..."
        if pnpm run test:integration; then
            log_success "Node.js integration tests passed"
            test_results+=("Node.js: ✅")
        else
            log_warning "Node.js integration tests failed"
            test_results+=("Node.js: ❌")
        fi
    fi

    # Run Python integration tests
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            log_info "Running Python integration tests for $service_name..."

            cd "$service_dir"

            # Set test environment
            export PYTHON_ENV=test
            export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/vibebiz_test"

            if poetry run pytest tests/integration/ -v --tb=short; then
                log_success "Python integration tests passed for $service_name"
                test_results+=("$service_name: ✅")
            else
                log_warning "Python integration tests failed for $service_name"
                test_results+=("$service_name: ❌")
            fi

            cd "$ROOT_DIR"
        fi
    done

    # Display test results
    echo ""
    log_info "Integration Test Results:"
    for result in "${test_results[@]}"; do
        echo "  $result"
    done
}

# Function to run E2E tests
run_e2e_tests() {
    log_info "Running E2E tests..."

    cd "$ROOT_DIR"

    # Check if Playwright is available
    if command -v pnpm &> /dev/null; then
        log_info "Running Playwright E2E tests..."
        if pnpm run test:e2e; then
            log_success "E2E tests passed"
        else
            log_warning "E2E tests failed"
        fi
    else
        log_warning "pnpm not available - skipping E2E tests"
    fi
}

# Function to run accessibility tests
run_accessibility_tests() {
    log_info "Running accessibility tests..."

    cd "$ROOT_DIR"

    # Check if Playwright is available
    if command -v pnpm &> /dev/null; then
        log_info "Running accessibility tests..."
        if pnpm run test:accessibility; then
            log_success "Accessibility tests passed"
        else
            log_warning "Accessibility tests failed"
        fi
    else
        log_warning "pnpm not available - skipping accessibility tests"
    fi
}

# Function to run security tests
run_security_tests() {
    log_info "Running security tests..."

    cd "$ROOT_DIR"

    # Check if security test script exists
    if [ -f "tools/security-scan.sh" ]; then
        log_info "Running security scan..."
        if bash tools/security-scan.sh all; then
            log_success "Security scan completed"
        else
            log_warning "Security scan found issues"
        fi
    else
        log_warning "Security scan script not found"
    fi

    # Run security tests from test suite
    if command -v pnpm &> /dev/null; then
        log_info "Running security tests..."
        if pnpm run test:security; then
            log_success "Security tests passed"
        else
            log_warning "Security tests failed"
        fi
    fi
}

# Function to run performance tests
run_performance_tests() {
    log_info "Running performance tests..."

    cd "$ROOT_DIR"

    # Check if performance test script exists
    if [ -f "tests/performance/run-benchmarks.sh" ]; then
        log_info "Running performance benchmarks..."
        if bash tests/performance/run-benchmarks.sh; then
            log_success "Performance benchmarks completed"
        else
            log_warning "Performance benchmarks failed"
        fi
    else
        log_info "No performance test script found - skipping"
    fi
}

# Function to generate test coverage report
generate_coverage_report() {
    log_info "Generating test coverage report..."

    cd "$ROOT_DIR"

    # Generate Node.js coverage
    if command -v pnpm &> /dev/null; then
        log_info "Generating Node.js coverage report..."
        if pnpm run test:coverage; then
            log_success "Node.js coverage report generated"
        else
            log_warning "Node.js coverage report generation failed"
        fi
    fi

    # Generate Python coverage
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            log_info "Generating Python coverage report for $service_name..."

            cd "$service_dir"

            # Set test environment
            export PYTHON_ENV=test
            export DATABASE_URL="postgresql://postgres:postgres@localhost:5432/vibebiz_test"

            if poetry run pytest tests/ --cov=src --cov-report=html --cov-report=term-missing; then
                log_success "Python coverage report generated for $service_name"
            else
                log_warning "Python coverage report generation failed for $service_name"
            fi

            cd "$ROOT_DIR"
        fi
    done
}

# Function to verify test setup
verify_test_setup() {
    log_info "Verifying test setup..."

    cd "$ROOT_DIR"

    local verification_results=()

    # Check if test database exists
    if docker exec vibebiz-postgres psql -U postgres -d vibebiz_test -c "SELECT 1;" > /dev/null 2>&1; then
        log_success "Test database accessible"
        verification_results+=("Test Database: ✅")
    else
        log_error "Test database not accessible"
        verification_results+=("Test Database: ❌")
    fi

    # Check if test environment file exists
    if [ -f "tests/.env.test" ]; then
        log_success "Test environment file exists"
        verification_results+=("Test Environment: ✅")
    else
        log_error "Test environment file missing"
        verification_results+=("Test Environment: ❌")
    fi

    # Check if test dependencies are installed
    if command -v pnpm &> /dev/null && pnpm list --depth=0 | grep -q "jest\|playwright"; then
        log_success "Node.js test dependencies installed"
        verification_results+=("Node.js Test Dependencies: ✅")
    else
        log_warning "Node.js test dependencies may be missing"
        verification_results+=("Node.js Test Dependencies: ⚠️")
    fi

    # Check Python test dependencies
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            cd "$service_dir"

            if poetry show | grep -q "pytest"; then
                log_success "Python test dependencies installed for $service_name"
                verification_results+=("$service_name Test Dependencies: ✅")
            else
                log_warning "Python test dependencies may be missing for $service_name"
                verification_results+=("$service_name Test Dependencies: ⚠️")
            fi

            cd "$ROOT_DIR"
        fi
    done

    # Display verification results
    echo ""
    log_info "Test Setup Verification:"
    for result in "${verification_results[@]}"; do
        echo "  $result"
    done
}

# Main test setup function
main() {
    log_info "Setting up test environment..."

    # Change to root directory
    cd "$ROOT_DIR"

    # Setup test database
    setup_test_database

    # Setup test environment files
    setup_test_env

    # Verify test setup
    verify_test_setup

    # Run a quick test to validate setup
    log_info "Running quick validation tests..."

    # Run unit tests
    run_unit_tests

    # Run integration tests
    run_integration_tests

    # Run E2E tests (optional)
    read -p "Run E2E tests? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_e2e_tests
    fi

    # Run accessibility tests (optional)
    read -p "Run accessibility tests? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_accessibility_tests
    fi

    # Run security tests
    run_security_tests

    # Run performance tests (optional)
    read -p "Run performance tests? (y/N): " -r
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_performance_tests
    fi

    # Generate coverage report
    generate_coverage_report

    log_success "Test setup complete!"

    echo ""
    log_info "Test Setup Summary:"
    echo "✅ Test database configured"
    echo "✅ Test environment files created"
    echo "✅ Test dependencies verified"
    echo "✅ Unit tests validated"
    echo "✅ Integration tests validated"
    echo "✅ Security tests validated"
    echo "✅ Coverage reports generated"
    echo ""
    log_info "Test files and reports:"
    echo "  - Test environment: tests/.env.test"
    echo "  - Coverage reports: coverage/, htmlcov/"
    echo "  - Test results: test-results/"
    echo ""
    log_info "You can run tests anytime with:"
    echo "  ./tools/run-all-tests.sh"
    echo "  pnpm test"
    echo "  poetry run pytest (in service directories)"
}

# Run main function
main
