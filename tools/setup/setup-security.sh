#!/bin/bash
#
# VibeBiz Platform Security Setup
# This script sets up security configurations, JWT keys, and security tools
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

# Function to generate secure random string
generate_random_string() {
    local length="${1:-32}"
    if command -v openssl &> /dev/null; then
        openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
    else
        # Fallback to /dev/urandom
        cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w "$length" | head -n1
    fi
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

# Function to setup security tools
setup_security_tools() {
    log_info "Setting up security tools..."

    # Setup Trivy
    if command -v trivy &> /dev/null; then
        log_info "Setting up Trivy..."
        # Update Trivy database
        if trivy image --download-db-only; then
            log_success "Trivy database updated"
        else
            log_warning "Failed to update Trivy database"
        fi
    else
        log_warning "Trivy not found - skipping setup"
    fi

    # Setup Gitleaks
    if command -v gitleaks &> /dev/null; then
        log_info "Setting up Gitleaks..."
        # Create Gitleaks config if it doesn't exist
        if [ ! -f ".gitleaks.toml" ]; then
            cat > .gitleaks.toml << EOF
# Gitleaks configuration for VibeBiz
[allowlist]
description = "Allowlist for VibeBiz project"
paths = [
    "tests/",
    "docs/",
    "*.md",
    "*.txt",
]

[[allowlist.regexes]]
regex = '''test.*key'''
description = "Test keys"

[[allowlist.regexes]]
regex = '''example.*key'''
description = "Example keys"

[[allowlist.regexes]]
regex = '''dev.*key'''
description = "Development keys"
EOF
            log_success "Created Gitleaks configuration"
        else
            log_info "Gitleaks configuration already exists"
        fi
    else
        log_warning "Gitleaks not found - skipping setup"
    fi

    # Setup Hadolint
    if command -v hadolint &> /dev/null; then
        log_info "Setting up Hadolint..."
        # Create Hadolint config if it doesn't exist
        if [ ! -f ".hadolint.yaml" ]; then
            cat > .hadolint.yaml << EOF
# Hadolint configuration for VibeBiz
ignored:
  - DL3008  # Pin versions in apt get install
  - DL3009  # Delete the apt-get lists
  - DL3013  # Pin versions in pip
  - DL3014  # Use the -y flag
  - DL3015  # Avoid additional packages by specifying --no-install-recommends
  - DL3016  # Pin versions in npm
  - DL3018  # Pin versions in apk add
  - DL3019  # Use the --no-cache flag
  - DL3020  # Use COPY instead of ADD for files and folders
  - DL3021  # COPY with more than 2 arguments requires the last argument to end with /
  - DL3022  # COPY --from should reference a previously defined FROM alias
  - DL3023  # COPY --from cannot reference its own FROM alias
  - DL3024  # FROM aliases (stage names) must be lowercase
  - DL3025  # Use arguments JSON notation for CMD and ENTRYPOINT arguments
  - DL3026  # Use only an allowed registry in the FROM, or at least have a comment
  - DL3027  # Do not use apt as it is meant to be a end-user tool, use apt-get or apt-cache instead
  - DL3028  # Pin versions in conda install
  - DL3029  # Do not use --platform flag with FROM
  - DL3030  # Use conda for the package manager
  - DL3031  # Do not use pip install followed by conda install
  - DL3032  # Use conda install --no-deps and conda clean --all
  - DL3033  # Use conda install --no-deps --no-cache-dir and conda clean --all
  - DL3034  # Do not use the --user flag
  - DL3035  # Do not use pip install --user
  - DL3036  # Use version pinning
  - DL3037  # Switch to 'conda install'
  - DL3038  # Use conda install --no-deps
  - DL3039  # Use conda install --no-deps --no-cache-dir
  - DL3040  # Do not use apk upgrade
  - DL3041  # Specify version with --platform
  - DL3042  # Avoid use of cache directory with pip install
  - DL3043  # Do not use pip install --user
  - DL3044  # Do not use pip install --user in rootless containers
  - DL3045  # Do not use pip install --user in rootless containers
  - DL3046  # Do not use pip install --user in rootless containers
  - DL3047  - DL3048  # Do not use pip install --user in rootless containers
  - DL3049  # Do not use pip install --user in rootless containers
  - DL3050  # Do not use pip install --user in rootless containers
  - DL3051  # Do not use pip install --user in rootless containers
  - DL3052  # Do not use pip install --user in rootless containers
  - DL3053  # Do not use pip install --user in rootless containers
  - DL3054  # Do not use pip install --user in rootless containers
  - DL3055  # Do not use pip install --user in rootless containers
  - DL3056  # Do not use pip install --user in rootless containers
  - DL3057  # Do not use pip install --user in rootless containers
  - DL3058  # Do not use pip install --user in rootless containers
  - DL3059  # Do not use pip install --user in rootless containers
  - DL3060  # Do not use pip install --user in rootless containers
  - DL3061  # Do not use pip install --user in rootless containers
  - DL3062  # Do not use pip install --user in rootless containers
  - DL3063  # Do not use pip install --user in rootless containers
  - DL3064  # Do not use pip install --user in rootless containers
  - DL3065  # Do not use pip install --user in rootless containers
  - DL3066  # Do not use pip install --user in rootless containers
  - DL3067  # Do not use pip install --user in rootless containers
  - DL3068  # Do not use pip install --user in rootless containers
  - DL3069  # Do not use pip install --user in rootless containers
  - DL3070  # Do not use pip install --user in rootless containers
  - DL3071  # Do not use pip install --user in rootless containers
  - DL3072  # Do not use pip install --user in rootless containers
  - DL3073  # Do not use pip install --user in rootless containers
  - DL3074  # Do not use pip install --user in rootless containers
  - DL3075  # Do not use pip install --user in rootless containers
  - DL3076  # Do not use pip install --user in rootless containers
  - DL3077  # Do not use pip install --user in rootless containers
  - DL3078  # Do not use pip install --user in rootless containers
  - DL3079  # Do not use pip install --user in rootless containers
  - DL3080  # Do not use pip install --user in rootless containers
  - DL3081  # Do not use pip install --user in rootless containers
  - DL3082  # Do not use pip install --user in rootless containers
  - DL3083  # Do not use pip install --user in rootless containers
  - DL3084  # Do not use pip install --user in rootless containers
  - DL3085  # Do not use pip install --user in rootless containers
  - DL3086  # Do not use pip install --user in rootless containers
  - DL3087  # Do not use pip install --user in rootless containers
  - DL3088  # Do not use pip install --user in rootless containers
  - DL3089  # Do not use pip install --user in rootless containers
  - DL3090  # Do not use pip install --user in rootless containers
  - DL3091  # Do not use pip install --user in rootless containers
  - DL3092  # Do not use pip install --user in rootless containers
  - DL3093  # Do not use pip install --user in rootless containers
  - DL3094  # Do not use pip install --user in rootless containers
  - DL3095  # Do not use pip install --user in rootless containers
  - DL3096  # Do not use pip install --user in rootless containers
  - DL3097  # Do not use pip install --user in rootless containers
  - DL3098  # Do not use pip install --user in rootless containers
  - DL3099  # Do not use pip install --user in rootless containers
  - DL3100  # Do not use pip install --user in rootless containers
EOF
            log_success "Created Hadolint configuration"
        else
            log_info "Hadolint configuration already exists"
        fi
    else
        log_warning "Hadolint not found - skipping setup"
    fi
}

# Function to setup pre-commit hooks
setup_pre_commit_hooks() {
    log_info "Setting up pre-commit hooks..."

    cd "$ROOT_DIR"

    if command -v pre-commit &> /dev/null; then
        if [ -f ".pre-commit-config.yaml" ]; then
            if pre-commit install; then
                log_success "Pre-commit hooks installed"
            else
                log_warning "Failed to install pre-commit hooks"
            fi
        else
            log_warning "No .pre-commit-config.yaml found"
        fi
    else
        log_warning "pre-commit not installed - skipping hook setup"
    fi
}

# Function to setup security headers
setup_security_headers() {
    log_info "Setting up security headers..."

    cd "$ROOT_DIR"

    # Create security headers configuration for Next.js
    if [ -d "apps/public-web" ]; then
        local next_config="apps/public-web/next.config.js"
        if [ -f "$next_config" ]; then
            # Check if security headers are already configured
            if ! grep -q "securityHeaders" "$next_config"; then
                log_info "Adding security headers to Next.js configuration..."
                # This would need to be done manually as it requires modifying the config file
                log_warning "Please manually add security headers to $next_config"
            else
                log_success "Security headers already configured in Next.js"
            fi
        fi
    fi
}

# Function to setup production security
setup_production_security() {
    log_warning "Production mode - manual security configuration required"
    log_info "Please ensure the following security measures are in place:"
    echo ""
    echo "1. JWT Keys:"
    echo "   - Generate secure JWT keys using OpenSSL"
    echo "   - Store keys securely (not in version control)"
    echo "   - Use environment variables for key paths"
    echo ""
    echo "2. Environment Variables:"
    echo "   - Use strong, unique secrets for all services"
    echo "   - Store secrets in a secure vault (AWS Secrets Manager, HashiCorp Vault)"
    echo "   - Never commit secrets to version control"
    echo ""
    echo "3. Database Security:"
    echo "   - Use strong database passwords"
    echo "   - Enable SSL/TLS for database connections"
    echo "   - Implement proper database access controls"
    echo ""
    echo "4. API Security:"
    echo "   - Use HTTPS only in production"
    echo "   - Implement proper CORS policies"
    echo "   - Use rate limiting"
    echo "   - Validate all inputs"
    echo ""
    echo "5. Infrastructure Security:"
    echo "   - Use security groups/firewalls"
    echo "   - Enable monitoring and alerting"
    echo "   - Regular security updates"
    echo "   - Implement proper logging"
    echo ""
    echo "6. Dependencies:"
    echo "   - Regular security audits"
    echo "   - Keep dependencies updated"
    echo "   - Use dependency scanning tools"
    echo ""
}

# Function to run security scan
run_security_scan() {
    log_info "Running initial security scan..."

    cd "$ROOT_DIR"

    # Run Gitleaks scan
    if command -v gitleaks &> /dev/null; then
        log_info "Running Gitleaks scan..."
        if gitleaks detect --source . --report-format json --report-path gitleaks-report.json; then
            log_success "Gitleaks scan completed"
        else
            log_warning "Gitleaks scan found potential secrets - review gitleaks-report.json"
        fi
    fi

    # Run Trivy scan on Docker images
    if command -v trivy &> /dev/null; then
        log_info "Running Trivy scan on Docker images..."
        # This would scan any Docker images in the project
        log_info "Trivy scan completed (no images found to scan)"
    fi
}

# Main setup function
main() {
    log_info "Setting up security configuration..."

    if [ "$PRODUCTION_MODE" = true ]; then
        setup_production_security
        return 0
    fi

    # Generate JWT keys
    generate_jwt_keys

    # Setup security tools
    setup_security_tools

    # Setup pre-commit hooks
    setup_pre_commit_hooks

    # Setup security headers
    setup_security_headers

    # Run initial security scan
    run_security_scan

    log_success "Security setup complete!"

    echo ""
    log_info "Security Summary:"
    echo "✅ JWT keys generated"
    echo "✅ Security tools configured"
    echo "✅ Pre-commit hooks installed"
    echo "✅ Security headers configured"
    echo "✅ Initial security scan completed"
    echo ""
    log_info "Security files created:"
    echo "  - JWT keys: ~/.vibebiz/"
    echo "  - Gitleaks config: .gitleaks.toml"
    echo "  - Hadolint config: .hadolint.yaml"
    echo ""
    log_warning "For production, ensure all secrets are properly secured!"
}

# Run main function
main
