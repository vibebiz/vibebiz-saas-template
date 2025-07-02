#!/bin/bash
#
# VibeBiz Platform Prerequisites Check
# This script checks if all required tools and dependencies are installed
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check command with version
check_command() {
    local cmd="$1"
    local min_version="$2"
    local version_flag="${3:---version}"

    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd is not installed or not in PATH"
        return 1
    fi

    if [ -n "$min_version" ]; then
        local current_version=$($cmd $version_flag 2>/dev/null | head -n1 || echo "")
        log_info "$cmd found: $current_version"

        # Simple version comparison (this is basic, could be improved)
        if [[ "$current_version" == *"$min_version"* ]]; then
            log_success "$cmd version check passed"
        else
            log_warning "$cmd version may be outdated (found: $current_version, expected: $min_version+)"
        fi
    else
        log_success "$cmd found"
    fi

    return 0
}

# Function to check Python version
check_python_version() {
    if command -v python3 &> /dev/null; then
        local version=$(python3 --version 2>&1 | cut -d' ' -f2)
        log_info "Python3 found: $version"

        # Extract major and minor version
        local major=$(echo "$version" | cut -d'.' -f1)
        local minor=$(echo "$version" | cut -d'.' -f2)

        if [ "$major" -ge 3 ] && [ "$minor" -ge 11 ]; then
            log_success "Python version check passed (3.11+)"

            # Check for externally managed environment (PEP 668)
            if python3 -c "import sys; print('externally-managed' in sys.prefix)" 2>/dev/null | grep -q "True"; then
                log_warning "Python is in an externally managed environment (PEP 668)"
                log_info "This is normal on modern macOS and Linux systems"
                log_info "The setup will use pipx or --user flag for package installation"
            fi
        else
            log_error "Python version too old: $version (requires 3.11+)"
            return 1
        fi
    else
        log_error "Python3 is not installed or not in PATH"
        return 1
    fi
}

# Function to check Node.js version
check_node_version() {
    if command -v node &> /dev/null; then
        local version=$(node --version 2>&1 | cut -c2-)
        log_info "Node.js found: $version"

        # Extract major version
        local major=$(echo "$version" | cut -d'.' -f1)

        if [ "$major" -ge 18 ]; then
            log_success "Node.js version check passed (18+)"
        else
            log_error "Node.js version too old: $version (requires 18+)"
            return 1
        fi
    else
        log_error "Node.js is not installed or not in PATH"
        return 1
    fi
}

# Function to check Docker
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed or not in PATH"
        return 1
    fi

    if ! docker info &> /dev/null; then
        log_warning "Docker is installed but not running"
        log_info "Please start Docker Desktop or Docker daemon"
        return 1
    fi

    local version=$(docker --version 2>&1)
    log_success "Docker found and running: $version"
}

# Function to check disk space
check_disk_space() {
    local required_space=5000000  # 5GB in KB

    # Detect OS and use appropriate command
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS - df output format is different
        local available_space=$(df . | awk 'NR==2 {print $4}' 2>/dev/null)
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        local available_space=$(df . | awk 'NR==2 {print $4}' 2>/dev/null)
    else
        # Windows or other - try to get disk space
        local available_space=$(df . | awk 'NR==2 {print $4}' 2>/dev/null || echo "0")
    fi

    if [ -n "$available_space" ] && [ "$available_space" -gt 0 ] && [ "$available_space" -gt "$required_space" ]; then
        log_success "Sufficient disk space available"
    elif [ -n "$available_space" ] && [ "$available_space" -gt 0 ]; then
        log_warning "Low disk space: $(($available_space / 1000))MB available, 5GB recommended"
    else
        log_warning "Could not determine disk space - ensure you have at least 5GB free"
    fi
}

# Function to check memory
check_memory() {
    local required_memory=4000000  # 4GB in KB

    # Detect OS and use appropriate command
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        local total_memory=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024)}')
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        local total_memory=$(free | awk 'NR==2{print $2}' 2>/dev/null)
    else
        # Windows or other - try to get memory info
        local total_memory=$(vmstat -s 2>/dev/null | grep "total memory" | awk '{print $1}' || echo "0")
    fi

    if [ -n "$total_memory" ] && [ "$total_memory" -gt 0 ] && [ "$total_memory" -gt "$required_memory" ]; then
        log_success "Sufficient memory available"
    elif [ -n "$total_memory" ] && [ "$total_memory" -gt 0 ]; then
        log_warning "Low memory: $(($total_memory / 1000))MB available, 4GB recommended"
    else
        log_warning "Could not determine memory size - ensure you have at least 4GB RAM"
    fi
}

# Main check function
main() {
    log_info "Checking prerequisites..."

    local missing_deps=()
    local warnings=()

    # Check core tools
    log_info "Checking core development tools..."

    if ! check_command "git" "" "--version"; then
        missing_deps+=("Git")
    fi

    if ! check_command "curl" "" "--version"; then
        missing_deps+=("curl")
    fi

    if ! check_command "wget" "" "--version"; then
        log_warning "wget not found (optional)"
        warnings+=("wget")
    fi

    # Check Node.js ecosystem
    log_info "Checking Node.js ecosystem..."

    if ! check_node_version; then
        missing_deps+=("Node.js (>=18.0.0)")
    fi

    if ! check_command "pnpm" "9.0.0" "--version"; then
        missing_deps+=("pnpm (>=9.0.0)")
    fi

    # Check Python ecosystem
    log_info "Checking Python ecosystem..."

    if ! check_python_version; then
        missing_deps+=("Python (>=3.11)")
    fi

    if ! check_command "poetry" "" "--version"; then
        missing_deps+=("Poetry")
    fi

    # Check Docker
    log_info "Checking Docker..."
    if ! check_docker; then
        missing_deps+=("Docker (running)")
    fi

    # Check security tools
    log_info "Checking security tools..."

    if ! check_command "trivy" "" "--version"; then
        log_warning "Trivy not found (optional for development)"
        warnings+=("trivy")
    fi

    if ! check_command "gitleaks" "" "--version"; then
        log_warning "Gitleaks not found (optional for development)"
        warnings+=("gitleaks")
    fi

    if ! check_command "hadolint" "" "--version"; then
        log_warning "Hadolint not found (optional for development)"
        warnings+=("hadolint")
    fi

    # Check additional tools
    log_info "Checking additional tools..."

    if ! check_command "jq" "" "--version"; then
        log_warning "jq not found (optional)"
        warnings+=("jq")
    fi

    if ! check_command "pre-commit" "" "--version"; then
        log_warning "pre-commit not found (optional)"
        warnings+=("pre-commit")
    fi

    # Check system resources
    log_info "Checking system resources..."
    check_disk_space
    check_memory

    # Check network connectivity
    log_info "Checking network connectivity..."
    if curl -s --max-time 10 https://registry.npmjs.org/ > /dev/null; then
        log_success "NPM registry accessible"
    else
        log_warning "Cannot access NPM registry - check your internet connection"
        warnings+=("internet-connectivity")
    fi

    if curl -s --max-time 10 https://pypi.org/ > /dev/null; then
        log_success "PyPI accessible"
    else
        log_warning "Cannot access PyPI - check your internet connection"
        warnings+=("internet-connectivity")
    fi

    # Summary
    echo ""
    if [ ${#missing_deps[@]} -eq 0 ]; then
        log_success "All required dependencies are installed!"

        if [ ${#warnings[@]} -gt 0 ]; then
            echo ""
            log_warning "Optional dependencies not found:"
            for warning in "${warnings[@]}"; do
                echo "  - $warning"
            done
            echo ""
            log_info "These are optional and won't prevent the setup from working"
        fi

        return 0
    else
        log_error "Missing required dependencies:"
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo ""
        log_info "Please install the missing dependencies and run setup again."
        log_info "You can run the OS-specific setup script to install them automatically."
        return 1
    fi
}

# Run main function
main
