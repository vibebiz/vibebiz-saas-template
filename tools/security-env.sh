#!/bin/bash
#
# VibeBiz Security Environment Setup
# Provides reusable, containerized security tooling for consistent validation
#
# Usage:
#   source ./tools/security-env.sh                    # Setup environment
#   ./tools/security-env.sh install                   # Install all tools
#   ./tools/security-env.sh validate                  # Run validation
#   ./tools/security-env.sh docker-scan <image>       # Scan with Docker

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SECURITY_ENV_VERSION="1.0.0"

# Security tool versions (single source of truth)
export GITLEAKS_VERSION="8.21.2"
export SEMGREP_VERSION="1.99.0"
export TRIVY_VERSION="0.58.1"
export HADOLINT_VERSION="2.12.0"
export BANDIT_VERSION="1.8.5"
export SAFETY_VERSION="3.2.11"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Check if running in container-supported environment
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_warning "Docker not available - falling back to local tools"
        return 1
    fi
    return 0
}

# Install security tools in isolated environment
install_tools() {
    log_info "Installing VibeBiz Security Environment v${SECURITY_ENV_VERSION}"

    # Create isolated npm environment for security tools
    if [ ! -d ".security-env" ]; then
        mkdir -p .security-env
        cd .security-env

        cat > package.json << EOF
{
  "name": "@vibebiz/security-env",
  "version": "${SECURITY_ENV_VERSION}",
  "private": true,
  "devDependencies": {
    "audit-ci": "^7.1.0",
    "better-npm-audit": "^3.7.3",
    "retire": "^5.2.7",
    "@sigstore/bundle": "^2.3.2",
    "@sigstore/sign": "^2.3.2",
    "@sigstore/verify": "^1.2.1"
  }
}
EOF

        npm install
        cd "$PROJECT_ROOT"
        log_success "Security environment created in .security-env/"
    fi

    # Install Python security tools in virtual environment
    if [ ! -d ".security-env/python" ]; then
        python3 -m venv .security-env/python
        source .security-env/python/bin/activate
        pip install bandit==${BANDIT_VERSION} safety==${SAFETY_VERSION}
        deactivate
        log_success "Python security tools installed"
    fi

    log_success "Security environment ready!"
}

# Containerized security scanning
docker_scan() {
    local scan_type="$1"
    local target="$2"

    case "$scan_type" in
        "secrets")
            docker run --rm -v "$PWD:/workspace" \
                zricethezav/gitleaks:v${GITLEAKS_VERSION} \
                detect --source /workspace --verbose
            ;;
        "static")
            docker run --rm -v "$PWD:/src" \
                semgrep/semgrep:${SEMGREP_VERSION} \
                --config=auto --error /src
            ;;
        "dependencies")
            docker run --rm -v "$PWD:/workspace" \
                aquasec/trivy:${TRIVY_VERSION} \
                fs /workspace --severity HIGH,CRITICAL
            ;;
        "container")
            if [ -z "$target" ]; then
                log_error "Container image name required for container scan"
                exit 1
            fi
            docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
                aquasec/trivy:${TRIVY_VERSION} \
                image "$target" --severity HIGH,CRITICAL
            ;;
        "dockerfile")
            docker run --rm -i \
                hadolint/hadolint:v${HADOLINT_VERSION} \
                < "${target:-Dockerfile}"
            ;;
        *)
            log_error "Unknown scan type: $scan_type"
            exit 1
            ;;
    esac
}

# Local security scanning with environment
local_scan() {
    local scan_type="$1"

    case "$scan_type" in
        "secrets")
            if command -v gitleaks &> /dev/null; then
                gitleaks detect --source . --verbose
            else
                log_error "Gitleaks not installed. Run: brew install gitleaks"
                exit 1
            fi
            ;;
        "static")
            # Use npm-installed tools from security environment
            cd .security-env && npx semgrep --config=auto --error ../ && cd ..
            ;;
        "dependencies")
            cd .security-env
            npx audit-ci --moderate ../ || true
            npx retire --path ../ --outputformat json --outputpath ../retire-report.json || true
            cd ..
            ;;
        "python-security")
            if [ -f ".security-env/python/bin/activate" ]; then
                source .security-env/python/bin/activate
                bandit -r services/ packages/ -f json -o bandit-report.json || true
                safety check --json --output safety-report.json || true
                deactivate
            else
                log_warning "Python security environment not found. Run: ./tools/security-env.sh install"
            fi
            ;;
        *)
            log_error "Unknown scan type: $scan_type"
            exit 1
            ;;
    esac
}

# Validate security environment
validate_environment() {
    log_info "Validating security environment..."

    local issues=0

    # Check for security environment
    if [ ! -d ".security-env" ]; then
        log_error "Security environment not found. Run: ./tools/security-env.sh install"
        issues=$((issues + 1))
    fi

    # Check tool versions
    if command -v gitleaks &> /dev/null; then
        local version=$(gitleaks version | grep -o 'v[0-9]*\.[0-9]*\.[0-9]*' || echo "unknown")
        if [ "$version" != "v${GITLEAKS_VERSION}" ]; then
            log_warning "Gitleaks version mismatch: expected v${GITLEAKS_VERSION}, got $version"
        fi
    fi

    if [ $issues -eq 0 ]; then
        log_success "Security environment validation passed"
        return 0
    else
        log_error "Security environment validation failed with $issues issues"
        return 1
    fi
}

# Main command handling
main() {
    case "${1:-help}" in
        "install")
            install_tools
            ;;
        "validate")
            validate_environment
            ;;
        "docker-scan")
            if check_docker; then
                docker_scan "$2" "$3"
            else
                log_error "Docker required for docker-scan command"
                exit 1
            fi
            ;;
        "local-scan")
            local_scan "$2"
            ;;
        "version")
            echo "VibeBiz Security Environment v${SECURITY_ENV_VERSION}"
            ;;
        "help"|*)
            cat << EOF
VibeBiz Security Environment v${SECURITY_ENV_VERSION}

Usage:
  ./tools/security-env.sh install                 # Install security environment
  ./tools/security-env.sh validate                # Validate environment setup
  ./tools/security-env.sh docker-scan <type>      # Run containerized scan
  ./tools/security-env.sh local-scan <type>       # Run local scan
  ./tools/security-env.sh version                 # Show version

Scan Types:
  secrets                                          # Secret scanning
  static                                           # Static analysis
  dependencies                                     # Dependency scanning
  container <image>                                # Container image scan
  dockerfile <file>                                # Dockerfile linting
  python-security                                  # Python-specific security

Examples:
  ./tools/security-env.sh install
  ./tools/security-env.sh docker-scan secrets
  ./tools/security-env.sh local-scan dependencies
  ./tools/security-env.sh docker-scan container myapp:latest

EOF
            ;;
    esac
}

# If sourced, just export functions. If executed, run main.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
