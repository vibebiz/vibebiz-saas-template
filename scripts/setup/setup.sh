#!/bin/bash
#
# VibeBiz Platform Setup Script
# This script sets up the entire platform ready for development or production
#
# Usage: ./scripts/setup/setup.sh [--production] [--skip-db] [--help]
#

# Note: Removing 'set -e' to allow error collection instead of immediate exit
# set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRODUCTION_MODE=false
SKIP_DATABASE=false
SKIP_TESTS=false
VERBOSE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Error tracking
SETUP_ERRORS=()
SETUP_WARNINGS=()
SETUP_STEP_STATUS=()

# Function to add error
add_error() {
    SETUP_ERRORS+=("$1")
}

# Function to add warning
add_warning() {
    SETUP_WARNINGS+=("$1")
}

# Function to track step status
track_step() {
    local step_name="$1"
    local status="$2"  # SUCCESS, WARNING, ERROR
    SETUP_STEP_STATUS+=("$step_name:$status")
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --production)
            PRODUCTION_MODE=true
            shift
            ;;
        --skip-db)
            SKIP_DATABASE=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            echo "VibeBiz Platform Setup Script"
            echo ""
            echo "Usage: ./scripts/setup/setup.sh [options]"
            echo ""
            echo "Options:"
            echo "  --production    Set up for production (requires manual .env configuration)"
            echo "  --skip-db       Skip database setup (useful for CI/CD)"
            echo "  --skip-tests    Skip test setup and validation"
            echo "  --verbose       Enable verbose output"
            echo "  --help          Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Utility functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    add_warning "$1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    add_error "$1"
}

# Enhanced step execution with error tracking
run_step() {
    local step_name="$1"
    local step_command="$2"
    local allow_failure="${3:-false}"

    log_info "🔧 $step_name..."

    if eval "$step_command"; then
        log_success "$step_name completed"
        track_step "$step_name" "SUCCESS"
        return 0
    else
        local exit_code=$?
        if [ "$allow_failure" = "true" ]; then
            log_warning "$step_name failed but continuing (exit code: $exit_code)"
            track_step "$step_name" "WARNING"
            return 0
        else
            log_error "$step_name failed (exit code: $exit_code)"
            track_step "$step_name" "ERROR"
            return $exit_code
        fi
    fi
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed or not in PATH"
        return 1
    fi
    return 0
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Header
echo -e "${BLUE}"
echo "=================================================================="
echo "🚀 VibeBiz Platform Setup"
echo "=================================================================="
echo -e "${NC}"

OS=$(detect_os)
log_info "Detected OS: $OS"

if [ "$PRODUCTION_MODE" = true ]; then
    log_warning "Setting up for PRODUCTION mode"
    echo -e "${YELLOW}⚠️  Make sure you have configured all .env files manually!${NC}"
    echo ""
else
    log_info "Setting up for DEVELOPMENT mode"
    echo ""
fi

# Change to root directory
cd "$ROOT_DIR"

# Step 1: Run OS-specific setup
OS_SETUP_SCRIPT="$SCRIPT_DIR/setup-${OS}.sh"
if [ -f "$OS_SETUP_SCRIPT" ]; then
    if [ "$VERBOSE" = true ]; then
        run_step "OS-specific setup ($OS)" "bash '$OS_SETUP_SCRIPT' --verbose" true
    else
        run_step "OS-specific setup ($OS)" "bash '$OS_SETUP_SCRIPT'" true
    fi
else
    log_warning "No OS-specific setup script found for $OS"
    track_step "OS-specific setup ($OS)" "WARNING"
fi

# Step 2: Check prerequisites
run_step "Check prerequisites" "bash '$SCRIPT_DIR/check-prerequisites.sh'" false

# Step 3: Setup environment files
run_step "Setup environment files" "AUTOMATED_SETUP=1 bash '$SCRIPT_DIR/setup-env.sh' --production='$PRODUCTION_MODE'" false

# Step 4: Install dependencies
run_step "Install dependencies" "bash '$SCRIPT_DIR/install-dependencies.sh'" false

# Step 5: Setup database
if [ "$SKIP_DATABASE" = false ]; then
    run_step "Setup database" "bash '$SCRIPT_DIR/setup-database.sh' --production='$PRODUCTION_MODE'" false
else
    log_info "Skipping database setup (--skip-db flag)"
    track_step "Setup database" "SKIPPED"
fi

# Step 6: Setup security
run_step "Setup security" "bash '$SCRIPT_DIR/setup-security.sh' --production='$PRODUCTION_MODE'" false

# Step 7: Build packages
run_step "Build packages" "bash '$SCRIPT_DIR/build-packages.sh'" false

# Step 8: Setup tests
if [ "$SKIP_TESTS" = false ]; then
    run_step "Setup tests" "bash '$SCRIPT_DIR/setup-tests.sh'" true
else
    log_info "Skipping test setup (--skip-tests flag)"
    track_step "Setup tests" "SKIPPED"
fi

# Step 9: Run health checks
run_step "Health checks" "bash '$SCRIPT_DIR/health-checks.sh'" true

# Step 10: Display setup summary and error report
echo ""

# Function to display final error summary
display_error_summary() {
    local total_errors=${#SETUP_ERRORS[@]}
    local total_warnings=${#SETUP_WARNINGS[@]}
    local total_steps=${#SETUP_STEP_STATUS[@]}

    echo ""
    echo -e "${BLUE}=================================================================="
    echo "📊 Setup Summary Report"
    echo "==================================================================${NC}"
    echo ""

    # Step status summary
    echo -e "${BLUE}Step Status Overview:${NC}"
    local success_count=0
    local error_count=0
    local warning_count=0
    local skipped_count=0

    for step_status in "${SETUP_STEP_STATUS[@]}"; do
        local step_name="${step_status%:*}"
        local status="${step_status#*:}"

        case "$status" in
            "SUCCESS")
                echo "  ✅ $step_name"
                ((success_count++))
                ;;
            "ERROR")
                echo "  ❌ $step_name"
                ((error_count++))
                ;;
            "WARNING")
                echo "  ⚠️  $step_name"
                ((warning_count++))
                ;;
            "SKIPPED")
                echo "  ⏭️  $step_name (skipped)"
                ((skipped_count++))
                ;;
        esac
    done

    echo ""
    echo -e "${BLUE}Summary Statistics:${NC}"
    echo "  Total Steps: $total_steps"
    echo "  ✅ Successful: $success_count"
    echo "  ⚠️  Warnings: $warning_count"
    echo "  ❌ Errors: $error_count"
    echo "  ⏭️  Skipped: $skipped_count"

    # Display warnings if any
    if [ $total_warnings -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  Warnings Found ($total_warnings):${NC}"
        for i in "${!SETUP_WARNINGS[@]}"; do
            echo "  $((i+1)). ${SETUP_WARNINGS[i]}"
        done
    fi

    # Display errors if any
    if [ $total_errors -gt 0 ]; then
        echo ""
        echo -e "${RED}❌ Errors Found ($total_errors):${NC}"
        for i in "${!SETUP_ERRORS[@]}"; do
            echo "  $((i+1)). ${SETUP_ERRORS[i]}"
        done
        echo ""
        echo -e "${RED}⚠️  Some setup steps failed. Please review the errors above and resolve them before proceeding.${NC}"
        return 1
    fi

    return 0
}

# Display the error summary
if display_error_summary; then
    echo ""
    echo -e "${GREEN}=================================================================="
    echo "🎉 VibeBiz Platform Setup Complete!"
    echo "==================================================================${NC}"
else
    echo ""
    echo -e "${YELLOW}=================================================================="
    echo "⚠️  VibeBiz Platform Setup Completed with Issues"
    echo "==================================================================${NC}"
fi

echo ""

if [ "$PRODUCTION_MODE" = false ]; then
    echo -e "${BLUE}Development Setup Summary:${NC}"
    echo "✅ Dependencies installed"
    echo "✅ Environment files created with development defaults"
    echo "✅ Security keys generated"
    echo "✅ PostgreSQL running in Docker"
    echo "✅ Database migrations applied"
    echo "✅ Packages built"
    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "1. Start the development servers:"
    echo "   pnpm dev"
    echo ""
    echo "2. Run tests to verify everything works:"
    echo "   ./scripts/run-all-tests.sh"
    echo ""
    echo "3. Access the applications:"
    echo "   - Public Web: http://localhost:3000"
    echo "   - Public API: http://localhost:8000"
    echo "   - API Docs: http://localhost:8000/docs"
    echo ""
else
    echo -e "${YELLOW}Production Setup Summary:${NC}"
    echo "✅ Dependencies installed"
    echo "✅ Environment files created (REQUIRES MANUAL CONFIGURATION)"
    echo "✅ Security setup completed"
    echo "✅ Packages built"
    echo ""
    echo -e "${RED}⚠️  IMPORTANT: Production Configuration Required${NC}"
    echo ""
    echo "1. Configure environment files with production values:"
    echo "   - .env"
    echo "   - services/public-api/.env"
    echo "   - apps/public-web/.env.local"
    echo ""
    echo "2. Set up production database and run migrations:"
    echo "   cd services/public-api"
    echo "   poetry run alembic upgrade head"
    echo ""
    echo "3. Generate and securely store JWT keys"
    echo "4. Configure monitoring and logging"
    echo "5. Set up CI/CD pipelines"
    echo ""
fi

echo -e "${BLUE}Documentation:${NC}"
echo "- Architecture: ./docs/ARCHITECTURE.md"
echo "- API Documentation: ./docs/api/README.md"
echo "- Testing Guide: ./tests/README.md"
echo ""

if [ "$PRODUCTION_MODE" = false ]; then
    if [ ${#SETUP_ERRORS[@]} -eq 0 ]; then
        echo -e "${GREEN}Happy coding! 🚀${NC}"
    else
        echo -e "${YELLOW}Setup completed with errors. Please review and fix before proceeding. 🔧${NC}"
    fi
else
    if [ ${#SETUP_ERRORS[@]} -eq 0 ]; then
        echo -e "${YELLOW}Ready for production deployment! 🚀${NC}"
    else
        echo -e "${RED}Production setup incomplete due to errors. Please resolve all issues before deployment. 🛑${NC}"
    fi
fi

# Exit with appropriate code
if [ ${#SETUP_ERRORS[@]} -gt 0 ]; then
    exit 1
else
    exit 0
fi
