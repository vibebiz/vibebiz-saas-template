#!/bin/bash
#
# VibeBiz Platform Health Checks
# This script runs comprehensive health checks to validate the setup
#

# Note: Removing 'set -e' to allow health check to continue and report all issues
# set -e

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

# Function to check command availability
check_command() {
    local cmd="$1"
    local description="$2"

    if command -v "$cmd" &> /dev/null; then
        log_success "$description: $cmd found"
        return 0
    else
        log_error "$description: $cmd not found"
        return 1
    fi
}

# Function to check version requirements
check_version() {
    local cmd="$1"
    local min_version="$2"
    local description="$3"

    if command -v "$cmd" &> /dev/null; then
        local version=$($cmd --version 2>/dev/null | head -n1 || echo "")
        log_info "$description: $version"

        # Simple version check (this could be improved)
        if [[ "$version" == *"$min_version"* ]]; then
            log_success "$description version check passed"
            return 0
        else
            log_warning "$description version may be outdated (found: $version, expected: $min_version+)"
            return 1
        fi
    else
        log_error "$description: $cmd not found"
        return 1
    fi
}

# Function to check environment files
check_env_files() {
    log_info "Checking environment files..."

    cd "$ROOT_DIR"

    local env_files=(
        ".env"
        "services/public-api/.env"
        "apps/public-web/.env.local"
        "tests/.env.test"
    )

    local missing_files=()

    for env_file in "${env_files[@]}"; do
        if [ -f "$env_file" ]; then
            log_success "Environment file exists: $env_file"
        else
            log_error "Environment file missing: $env_file"
            missing_files+=("$env_file")
        fi
    done

    if [ ${#missing_files[@]} -gt 0 ]; then
        log_warning "Missing environment files:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi

    return 0
}

# Function to check database connectivity
check_database() {
    log_info "Checking database connectivity..."

    # Check if PostgreSQL container is running
    if ! docker ps | grep -q "vibebiz-postgres"; then
        log_error "PostgreSQL container is not running"
        return 1
    fi

    # Check if we can connect to the database
    if docker exec vibebiz-postgres psql -U postgres -d vibebiz_dev -c "SELECT version();" > /dev/null 2>&1; then
        log_success "Database connection successful"
    else
        log_error "Cannot connect to database"
        return 1
    fi

    # Check if tables exist
    local table_count=$(docker exec vibebiz-postgres psql -U postgres -d vibebiz_dev -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')

    if [ "$table_count" -gt 0 ]; then
        log_success "Database contains $table_count tables"
    else
        log_warning "Database appears to be empty - migrations may not have run"
    fi

    return 0
}

# Function to check dependencies
check_dependencies() {
    log_info "Checking dependencies..."

    cd "$ROOT_DIR"

    # Check Node.js dependencies
    if command -v pnpm &> /dev/null; then
        if pnpm list --depth=0 > /dev/null 2>&1; then
            log_success "Node.js dependencies installed"
        else
            log_error "Node.js dependencies not properly installed"
            return 1
        fi
    fi

    # Check Python dependencies
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            cd "$service_dir"

            if poetry show > /dev/null 2>&1; then
                log_success "Python dependencies installed for $service_name"
            else
                log_error "Python dependencies not properly installed for $service_name"
                cd "$ROOT_DIR"
                return 1
            fi

            cd "$ROOT_DIR"
        fi
    done

    return 0
}

# Function to check build artifacts
check_builds() {
    log_info "Checking build artifacts..."

    cd "$ROOT_DIR"

    local build_artifacts=()
    local missing_builds=()

    # Check for Next.js builds
    for app_dir in apps/*/; do
        if [ -f "$app_dir/package.json" ]; then
            app_name=$(basename "$app_dir")
            if [ -d "$app_dir/.next" ]; then
                build_artifacts+=("$app_name (.next)")
            else
                missing_builds+=("$app_name")
            fi
        fi
    done

    # Check for Python builds
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            if [ -d "$service_dir/dist" ]; then
                build_artifacts+=("$service_name (dist)")
            else
                missing_builds+=("$service_name")
            fi
        fi
    done

    if [ ${#build_artifacts[@]} -gt 0 ]; then
        log_success "Build artifacts found:"
        for artifact in "${build_artifacts[@]}"; do
            echo "  - $artifact"
        done
    fi

    if [ ${#missing_builds[@]} -gt 0 ]; then
        log_warning "Missing builds:"
        for build in "${missing_builds[@]}"; do
            echo "  - $build"
        done
        return 1
    fi

    return 0
}

# Function to check security setup
check_security() {
    log_info "Checking security setup..."

    cd "$ROOT_DIR"

    local security_checks=()

    # Check JWT keys
    if [ -f "$HOME/.vibebiz/jwt_private_key.pem" ] && [ -f "$HOME/.vibebiz/jwt_public_key.pem" ]; then
        log_success "JWT keys exist"
        security_checks+=("JWT Keys: ✅")
    else
        log_warning "JWT keys missing"
        security_checks+=("JWT Keys: ❌")
    fi

    # Check security tools
    if command -v trivy &> /dev/null; then
        security_checks+=("Trivy: ✅")
    else
        security_checks+=("Trivy: ❌")
    fi

    if command -v gitleaks &> /dev/null; then
        security_checks+=("Gitleaks: ✅")
    else
        security_checks+=("Gitleaks: ❌")
    fi

    if command -v hadolint &> /dev/null; then
        security_checks+=("Hadolint: ✅")
    else
        security_checks+=("Hadolint: ❌")
    fi

    # Check security configuration files
    if [ -f ".gitleaks.toml" ]; then
        security_checks+=("Gitleaks Config: ✅")
    else
        security_checks+=("Gitleaks Config: ❌")
    fi

    if [ -f ".hadolint.yaml" ]; then
        security_checks+=("Hadolint Config: ✅")
    else
        security_checks+=("Hadolint Config: ❌")
    fi

    # Display security check results
    echo ""
    log_info "Security Setup:"
    for check in "${security_checks[@]}"; do
        echo "  $check"
    done

    return 0
}

# Function to check test setup
check_tests() {
    log_info "Checking test setup..."

    cd "$ROOT_DIR"

    local test_checks=()

    # Check test database
    if docker exec vibebiz-postgres psql -U postgres -d vibebiz_test -c "SELECT 1;" > /dev/null 2>&1; then
        test_checks+=("Test Database: ✅")
    else
        test_checks+=("Test Database: ❌")
    fi

    # Check test environment file
    if [ -f "tests/.env.test" ]; then
        test_checks+=("Test Environment: ✅")
    else
        test_checks+=("Test Environment: ❌")
    fi

    # Check test dependencies
    if command -v pnpm &> /dev/null && pnpm list --depth=0 | grep -q "jest\|playwright"; then
        test_checks+=("Node.js Test Dependencies: ✅")
    else
        test_checks+=("Node.js Test Dependencies: ❌")
    fi

    # Check Python test dependencies
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            cd "$service_dir"

            if poetry show | grep -q "pytest"; then
                test_checks+=("$service_name Test Dependencies: ✅")
            else
                test_checks+=("$service_name Test Dependencies: ❌")
            fi

            cd "$ROOT_DIR"
        fi
    done

    # Display test check results
    echo ""
    log_info "Test Setup:"
    for check in "${test_checks[@]}"; do
        echo "  $check"
    done

    return 0
}

# Function to run quick functionality tests
run_functionality_tests() {
    log_info "Running quick functionality tests..."

    cd "$ROOT_DIR"

    local test_results=()

    # Test TypeScript compilation
    if command -v pnpm &> /dev/null; then
        log_info "Testing TypeScript compilation..."
        if pnpm run type-check > /dev/null 2>&1; then
            log_success "TypeScript compilation successful"
            test_results+=("TypeScript Compilation: ✅")
        else
            log_error "TypeScript compilation failed"
            test_results+=("TypeScript Compilation: ❌")
        fi
    fi

    # Test Python imports
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            log_info "Testing Python imports for $service_name..."

            cd "$service_dir"

            if poetry run python -c "import src" > /dev/null 2>&1; then
                log_success "Python imports successful for $service_name"
                test_results+=("$service_name Python Imports: ✅")
            else
                log_error "Python imports failed for $service_name"
                test_results+=("$service_name Python Imports: ❌")
            fi

            cd "$ROOT_DIR"
        fi
    done

    # Test Docker images
    if command -v docker &> /dev/null; then
        log_info "Testing Docker images..."
        local docker_images=$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "vibebiz-" || true)
        if [ -n "$docker_images" ]; then
            log_success "Docker images found"
            test_results+=("Docker Images: ✅")
        else
            log_warning "No Docker images found"
            test_results+=("Docker Images: ⚠️")
        fi
    fi

    # Display functionality test results
    echo ""
    log_info "Functionality Tests:"
    for result in "${test_results[@]}"; do
        echo "  $result"
    done

    return 0
}

# Function to check network connectivity
check_network() {
    log_info "Checking network connectivity..."

    local connectivity_checks=()

    # Check NPM registry
    if curl -s --max-time 10 https://registry.npmjs.org/ > /dev/null; then
        connectivity_checks+=("NPM Registry: ✅")
    else
        connectivity_checks+=("NPM Registry: ❌")
    fi

    # Check PyPI
    if curl -s --max-time 10 https://pypi.org/ > /dev/null; then
        connectivity_checks+=("PyPI: ✅")
    else
        connectivity_checks+=("PyPI: ❌")
    fi

    # Check Docker Hub
    if curl -s --max-time 10 https://hub.docker.com/ > /dev/null; then
        connectivity_checks+=("Docker Hub: ✅")
    else
        connectivity_checks+=("Docker Hub: ❌")
    fi

    # Display connectivity check results
    echo ""
    log_info "Network Connectivity:"
    for check in "${connectivity_checks[@]}"; do
        echo "  $check"
    done

    return 0
}

# Function to generate health report
generate_health_report() {
    log_info "Generating health report..."

    cd "$ROOT_DIR"

    local report_file="health-check-report.txt"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "$report_file" << EOF
VibeBiz Platform Health Check Report
Generated: $timestamp

SYSTEM INFORMATION:
$(uname -a)

ENVIRONMENT:
$(env | grep -E "(NODE_ENV|PYTHON_ENV|PATH)" | sort)

DEPENDENCIES:
Node.js: $(node --version 2>/dev/null || echo "Not found")
pnpm: $(pnpm --version 2>/dev/null || echo "Not found")
Python: $(python3 --version 2>/dev/null || echo "Not found")
Poetry: $(poetry --version 2>/dev/null || echo "Not found")
Docker: $(docker --version 2>/dev/null || echo "Not found")

DATABASE:
$(docker exec vibebiz-postgres psql -U postgres -d vibebiz_dev -c "SELECT version();" 2>/dev/null || echo "Database not accessible")

BUILD ARTIFACTS:
$(find . -name ".next" -o -name "dist" -o -name "build" 2>/dev/null | head -10)

DOCKER IMAGES:
$(docker images --format "{{.Repository}}:{{.Tag}}" | grep "vibebiz-" 2>/dev/null || echo "No VibeBiz images found")

EOF

    log_success "Health report generated: $report_file"
}

# Main health check function
main() {
    log_info "Running comprehensive health checks..."

    # Change to root directory
    cd "$ROOT_DIR"

    local overall_status=0

    # Check prerequisites
    log_info "Checking prerequisites..."
    check_command "node" "Node.js" || overall_status=1
    check_command "pnpm" "pnpm" || overall_status=1
    check_command "python3" "Python" || overall_status=1
    check_command "poetry" "Poetry" || overall_status=1
    check_command "docker" "Docker" || overall_status=1

    # Check versions
    log_info "Checking versions..."
    check_version "node" "18" "Node.js" || overall_status=1
    check_version "pnpm" "9" "pnpm" || overall_status=1
    check_version "python3" "3.11" "Python" || overall_status=1

    # Check environment files
    check_env_files || overall_status=1

    # Check database
    check_database || overall_status=1

    # Check dependencies
    check_dependencies || overall_status=1

    # Check builds
    check_builds || overall_status=1

    # Check security
    check_security

    # Check tests
    check_tests

    # Check network
    check_network

    # Run functionality tests
    run_functionality_tests

    # Generate health report
    generate_health_report

    # Final summary
    echo ""
    echo -e "${BLUE}=================================================================="
    echo "🏥 Health Check Summary"
    echo "==================================================================${NC}"
    echo ""

    if [ $overall_status -eq 0 ]; then
        log_success "All critical health checks passed!"
        echo ""
        log_info "Your VibeBiz platform is ready for development!"
        echo ""
        log_info "Next steps:"
        echo "1. Start development servers: pnpm dev"
        echo "2. Run tests: ./scripts/run-all-tests.sh"
        echo "3. Access applications:"
        echo "   - Public Web: http://localhost:3000"
        echo "   - Public API: http://localhost:8000"
        echo "   - API Docs: http://localhost:8000/docs"
        echo ""
        log_success "Happy coding! 🚀"
    else
        log_error "Some health checks failed!"
        echo ""
        log_warning "Please review the issues above and fix them before proceeding."
        echo ""
        log_info "Common fixes:"
        echo "1. Install missing dependencies"
        echo "2. Configure environment files"
        echo "3. Start required services (Docker, PostgreSQL)"
        echo "4. Run setup scripts again"
        echo ""
        log_error "Setup incomplete - please resolve issues and run health checks again."
    fi

    return $overall_status
}

# Run main function
main
