#!/bin/bash
#
# VibeBiz Platform Setup Script
# This script sets up the entire platform ready for development or production
#
# Usage: ./tools/setup/setup.sh [--production] [--skip-db] [--help]
#

set -e  # Exit on any error

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
            echo "Usage: ./tools/setup/setup.sh [options]"
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
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
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
log_info "🔧 Running OS-specific setup..."
OS_SETUP_SCRIPT="$SCRIPT_DIR/setup-${OS}.sh"
if [ -f "$OS_SETUP_SCRIPT" ]; then
    if [ "$VERBOSE" = true ]; then
        bash "$OS_SETUP_SCRIPT" --verbose
    else
        bash "$OS_SETUP_SCRIPT"
    fi
else
    log_warning "No OS-specific setup script found for $OS"
fi

# Step 2: Check prerequisites
log_info "🔍 Checking prerequisites..."
bash "$SCRIPT_DIR/check-prerequisites.sh"

# Step 3: Setup environment files
log_info "📝 Setting up environment files..."
bash "$SCRIPT_DIR/setup-env.sh" --production="$PRODUCTION_MODE"

# Step 4: Install dependencies
log_info "📦 Installing dependencies..."
bash "$SCRIPT_DIR/install-dependencies.sh"

# Step 5: Setup database
if [ "$SKIP_DATABASE" = false ]; then
    log_info "🗄️  Setting up database..."
    bash "$SCRIPT_DIR/setup-database.sh" --production="$PRODUCTION_MODE"
else
    log_info "Skipping database setup (--skip-db flag)"
fi

# Step 6: Setup security
log_info "🔒 Setting up security..."
bash "$SCRIPT_DIR/setup-security.sh" --production="$PRODUCTION_MODE"

# Step 7: Build packages
log_info "🔨 Building packages..."
bash "$SCRIPT_DIR/build-packages.sh"

# Step 8: Setup tests
if [ "$SKIP_TESTS" = false ]; then
    log_info "🧪 Setting up tests..."
    bash "$SCRIPT_DIR/setup-tests.sh"
else
    log_info "Skipping test setup (--skip-tests flag)"
fi

# Step 9: Run health checks
log_info "🏥 Running health checks..."
bash "$SCRIPT_DIR/health-checks.sh"

# Step 10: Display setup summary
echo ""
echo -e "${GREEN}=================================================================="
echo "🎉 VibeBiz Platform Setup Complete!"
echo "==================================================================${NC}"
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
    echo "   ./tools/run-all-tests.sh"
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
    echo -e "${GREEN}Happy coding! 🚀${NC}"
else
    echo -e "${YELLOW}Ready for production deployment! 🚀${NC}"
fi
