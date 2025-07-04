#!/bin/bash
#
# VibeBiz Platform Environment Setup
# This script sets up environment files for the platform
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PRODUCTION_MODE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --production)
            PRODUCTION_MODE=true
            shift
            ;;
        *)
            shift
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

# Function to create environment file
create_env_file() {
    local example_file="$1"
    local target_file="$2"
    local service_name="$3"
    local env_type="$4"

    if [ ! -f "$example_file" ]; then
        log_warning "Example file not found: $example_file"
        return 1
    fi

    if [ -f "$target_file" ]; then
        log_warning "$service_name environment file already exists: $target_file"
        # In automation mode, don't overwrite existing files
        if [ -n "${CI:-}" ] || [ -n "${AUTOMATED_SETUP:-}" ]; then
            log_info "Skipping $service_name environment setup (automated mode)"
            return 0
        else
            # Check if we're in a non-interactive shell
            if [ ! -t 0 ]; then
                log_info "Skipping $service_name environment setup (non-interactive)"
                return 0
            fi
            read -p "Overwrite? (y/N): " -r
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log_info "Skipping $service_name environment setup"
                return 0
            fi
        fi
    fi

    # Create directory if it doesn't exist
    local target_dir=$(dirname "$target_file")
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    cp "$example_file" "$target_file"
    log_success "Created $service_name environment file: $target_file"

    if [ "$PRODUCTION_MODE" = false ]; then
        # Set development defaults
        case "$env_type" in
            "root")
                configure_root_env "$target_file"
                ;;
            "public-api")
                configure_public_api_env "$target_file"
                ;;
            "public-web")
                configure_public_web_env "$target_file"
                ;;
            "tests")
                configure_tests_env "$target_file"
                ;;
        esac
    fi

    return 0
}

# Function to configure root environment
configure_root_env() {
    local env_file="$1"

    log_info "Configuring root environment for development..."

    # Replace production values with development defaults
    sed -i.bak 's|NODE_ENV=production|NODE_ENV=development|g' "$env_file"
    sed -i.bak 's|PYTHON_ENV=production|PYTHON_ENV=development|g' "$env_file"
    sed -i.bak 's|LOG_LEVEL=info|LOG_LEVEL=debug|g' "$env_file"
    sed -i.bak 's|CI=true|CI=false|g' "$env_file"

    # Set development-specific values
    echo "" >> "$env_file"
    echo "# Development overrides" >> "$env_file"
    echo "SPECTRAL_DSN=dev-spectral-dsn-optional" >> "$env_file"
    echo "DEBUG=true" >> "$env_file"
    echo "ENABLE_SWAGGER=true" >> "$env_file"

    rm -f "$env_file.bak"
}

# Function to configure public API environment
configure_public_api_env() {
    local env_file="$1"

    log_info "Configuring public API environment for development..."

    # Replace production values with development defaults
    sed -i.bak 's|DATABASE_URL=postgresql://.*|DATABASE_URL=postgresql://postgres:postgres@localhost:5432/vibebiz_dev|g' "$env_file"
    sed -i.bak 's|PYTHON_ENV=production|PYTHON_ENV=development|g' "$env_file"
    sed -i.bak 's|LOG_LEVEL=INFO|LOG_LEVEL=DEBUG|g' "$env_file"

    # Set development-specific values
    echo "" >> "$env_file"
    echo "# Development overrides" >> "$env_file"
    echo "API_KEYS=dev-api-key,test-api-key,admin-key-dev" >> "$env_file"
    echo "DEBUG=true" >> "$env_file"
    echo "ENABLE_SWAGGER=true" >> "$env_file"
    echo "CORS_ORIGINS=http://localhost:3000,http://localhost:3001" >> "$env_file"

    rm -f "$env_file.bak"
}

# Function to configure public web environment
configure_public_web_env() {
    local env_file="$1"

    log_info "Configuring public web environment for development..."

    # Replace production values with development defaults
    sed -i.bak 's|NODE_ENV=production|NODE_ENV=development|g' "$env_file"
    sed -i.bak 's|NEXT_PUBLIC_API_URL=https://.*|NEXT_PUBLIC_API_URL=http://localhost:8000|g' "$env_file"

    # Set development-specific values
    echo "" >> "$env_file"
    echo "# Development overrides" >> "$env_file"
    echo "NEXT_PUBLIC_APP_URL=http://localhost:3000" >> "$env_file"
    echo "DEBUG=true" >> "$env_file"

    rm -f "$env_file.bak"
}

# Function to configure tests environment
configure_tests_env() {
    local env_file="$1"

    log_info "Configuring tests environment for development..."

    # Replace production values with development defaults
    sed -i.bak 's|NODE_ENV=test|NODE_ENV=test|g' "$env_file"
    sed -i.bak 's|PYTHON_ENV=test|PYTHON_ENV=test|g' "$env_file"
    sed -i.bak 's|CI=true|CI=false|g' "$env_file"
    sed -i.bak 's|LOG_LEVEL=warning|LOG_LEVEL=debug|g' "$env_file"

    # Set development-specific values
    echo "" >> "$env_file"
    echo "# Development overrides" >> "$env_file"
    echo "SPECTRAL_DSN=dev-test-spectral-optional" >> "$env_file"
    echo "TEST_DATABASE_URL=postgresql://postgres:postgres@localhost:5432/vibebiz_test" >> "$env_file"

    rm -f "$env_file.bak"
}

# Function to generate secure random string
generate_random_string() {
    local length="${1:-32}"
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

# Function to generate JWT keys
generate_jwt_keys() {
    local jwt_dir="$HOME/.vibebiz"
    mkdir -p "$jwt_dir"
    chmod 700 "$jwt_dir"

    if [ ! -f "$jwt_dir/jwt_private_key.pem" ] || [ ! -f "$jwt_dir/jwt_public_key.pem" ]; then
        log_info "Generating JWT keys..."

        if command -v openssl &> /dev/null; then
            # Generate Ed25519 key pair
            openssl genpkey -algorithm Ed25519 -out "$jwt_dir/jwt_private_key.pem"
            openssl pkey -in "$jwt_dir/jwt_private_key.pem" -pubout -out "$jwt_dir/jwt_public_key.pem"
            chmod 600 "$jwt_dir/jwt_private_key.pem"
            chmod 644 "$jwt_dir/jwt_public_key.pem"
            log_success "JWT keys generated in $jwt_dir"
        else
            log_warning "OpenSSL not found - JWT keys will be generated at runtime"
        fi
    else
        log_success "JWT keys already exist"
    fi
}

# Main setup function
main() {
    log_info "Setting up environment files..."

    # Change to root directory
    cd "$ROOT_DIR"

    # Create root environment file
    if [ -f ".env.example" ]; then
        create_env_file ".env.example" ".env" "Root" "root"
    else
        log_warning "No .env.example found in root directory"
        # Create a basic .env file
        cat > .env << EOF
# VibeBiz Platform Environment Configuration
NODE_ENV=development
PYTHON_ENV=development
LOG_LEVEL=debug
CI=false

# Development overrides
SPECTRAL_DSN=dev-spectral-dsn-optional
DEBUG=true
ENABLE_SWAGGER=true

# Security
JWT_SECRET_KEY=$(generate_random_string 64)
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/vibebiz_dev

# API Configuration
API_KEYS=dev-api-key,test-api-key,admin-key-dev
CORS_ORIGINS=http://localhost:3000,http://localhost:3001

# External Services
STRIPE_SECRET_KEY=sk_test_your_stripe_test_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
EOF
        log_success "Created basic .env file"
    fi

    # Create public API environment file
    if [ -f "services/public-api/.env.example" ]; then
        create_env_file "services/public-api/.env.example" "services/public-api/.env" "Public API" "public-api"
    else
        log_warning "No .env.example found in public-api service"
        # Create a basic public API .env file
        cat > services/public-api/.env << EOF
# VibeBiz Public API Environment Configuration
PYTHON_ENV=development
LOG_LEVEL=DEBUG

# Database
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/vibebiz_dev

# Security
JWT_SECRET_KEY=$(generate_random_string 64)
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30
JWT_REFRESH_TOKEN_EXPIRE_DAYS=7

# API Configuration
API_KEYS=dev-api-key,test-api-key,admin-key-dev
DEBUG=true
ENABLE_SWAGGER=true
CORS_ORIGINS=http://localhost:3000,http://localhost:3001

# External Services
STRIPE_SECRET_KEY=sk_test_your_stripe_test_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret_here
EOF
        log_success "Created basic public-api .env file"
    fi

    # Create public web environment file
    if [ -f "apps/public-web/.env.example" ]; then
        create_env_file "apps/public-web/.env.example" "apps/public-web/.env.local" "Public Web" "public-web"
    else
        log_warning "No .env.example found in public-web app"
        # Create a basic public web .env.local file
        cat > apps/public-web/.env.local << EOF
# VibeBiz Public Web Environment Configuration
NODE_ENV=development

# API Configuration
NEXT_PUBLIC_API_URL=http://localhost:8000
NEXT_PUBLIC_APP_URL=http://localhost:3000

# Development overrides
DEBUG=true
EOF
        log_success "Created basic public-web .env.local file"
    fi

    # Create tests environment file
    if [ -f "tests/.env.example" ]; then
        create_env_file "tests/.env.example" "tests/.env.test" "Tests" "tests"
    else
        log_warning "No .env.example found in tests directory"
        # Create a basic tests .env.test file
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
EOF
        log_success "Created basic tests .env.test file"
    fi

    # Generate JWT keys for development
    if [ "$PRODUCTION_MODE" = false ]; then
        generate_jwt_keys
    fi

    log_success "Environment files setup complete!"

    if [ "$PRODUCTION_MODE" = true ]; then
        echo ""
        log_warning "Production mode - please manually configure the following:"
        echo "  - Database URLs and credentials"
        echo "  - JWT secret keys"
        echo "  - API keys"
        echo "  - External service credentials (Stripe, etc.)"
        echo "  - CORS origins"
        echo "  - Log levels"
    fi
}

# Run main function
main
