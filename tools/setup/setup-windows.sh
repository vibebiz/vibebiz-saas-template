#!/bin/bash
#
# VibeBiz Platform Setup Script - Windows
# This script sets up the Windows environment for VibeBiz development
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

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

log_info "Setting up Windows environment..."

# Check if running in WSL
if grep -qi microsoft /proc/version; then
    log_info "Detected WSL environment"
    log_warning "For best experience, consider using the Linux setup script instead"
    log_info "Running Linux setup script..."
    bash "$(dirname "$0")/setup-linux.sh"
    exit 0
fi

# Check if running in Git Bash or similar
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
    log_info "Detected Git Bash/Cygwin environment"
else
    log_warning "This script is designed for Git Bash or WSL on Windows"
    log_info "Please run this script in Git Bash or install WSL"
    exit 1
fi

# Check if Chocolatey is installed
if ! command -v choco &> /dev/null; then
    log_info "Installing Chocolatey..."
    powershell -Command "Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
    log_success "Chocolatey installed"
else
    log_success "Chocolatey already installed"
fi

# Function to install a tool with Chocolatey if missing
install_with_choco() {
    local tool_name="$1"
    local choco_pkg_name="${2:-$1}"

    if ! command -v "$tool_name" &> /dev/null; then
        log_info "Installing $tool_name with Chocolatey..."
        choco install "$choco_pkg_name" -y
        log_success "$tool_name installed"
    else
        log_info "$tool_name already installed"
    fi
}

# Install required tools
log_info "Installing required tools..."

# Node.js and pnpm
install_with_choco nodejs "nodejs"
install_with_choco pnpm "pnpm"

# Python and Poetry
install_with_choco python "python"
install_with_choco poetry "poetry"

# Git
install_with_choco git "git"

# Docker Desktop
if ! command -v docker &> /dev/null; then
    log_info "Installing Docker Desktop..."
    choco install docker-desktop -y
    log_success "Docker Desktop installed"
    log_warning "Please start Docker Desktop manually after installation"
else
    log_info "Docker already installed"
fi

# Install additional tools
install_with_choco jq "jq"

# Install security tools
install_security_tools() {
    # Install Trivy
    if ! command -v trivy &> /dev/null; then
        log_info "Installing Trivy..."
        choco install trivy -y
        log_success "Trivy installed"
    else
        log_info "Trivy already installed"
    fi

    # Install Gitleaks
    if ! command -v gitleaks &> /dev/null; then
        log_info "Installing Gitleaks..."
        choco install gitleaks -y
        log_success "Gitleaks installed"
    else
        log_info "Gitleaks already installed"
    fi

    # Install Hadolint
    if ! command -v hadolint &> /dev/null; then
        log_info "Installing Hadolint..."
        choco install hadolint -y
        log_success "Hadolint installed"
    else
        log_info "Hadolint already installed"
    fi
}

install_security_tools

# Install pre-commit
if ! command -v pre-commit &> /dev/null; then
    log_info "Installing pre-commit..."
    # Try pipx first, then fallback to pip --user
    if command -v pipx &> /dev/null; then
        pipx install pre-commit
        log_success "pre-commit installed with pipx"
    else
        # Try to install pipx first
        if pip install --user pipx; then
            export PATH="$HOME/.local/bin:$PATH"
            pipx install pre-commit
            log_success "pre-commit installed with pipx"
        else
            # Fallback to direct pip install
            if pip install --user pre-commit; then
                log_success "pre-commit installed with pip"
            else
                log_warning "Failed to install pre-commit - you may need to install it manually"
            fi
        fi
    fi
else
    log_info "pre-commit already installed"
fi

# Setup Git configuration if not already set
if [ -z "$(git config --global user.name)" ]; then
    log_warning "Git user.name not configured. Please run:"
    echo "  git config --global user.name 'Your Name'"
    echo "  git config --global user.email 'your.email@example.com'"
fi

# Check if Docker Desktop is running
if ! docker info &> /dev/null; then
    log_warning "Docker is not running. Please start Docker Desktop and try again."
    log_info "You can start Docker Desktop from the Start menu or run:"
    echo "  start 'C:\Program Files\Docker\Docker\Docker Desktop.exe'"
fi

# Windows-specific recommendations
log_info "Windows-specific setup recommendations:"

echo ""
echo -e "${BLUE}Recommended Windows Setup:${NC}"
echo "1. Install Windows Terminal from Microsoft Store for better terminal experience"
echo "2. Install VS Code with the following extensions:"
echo "   - Python"
echo "   - TypeScript and JavaScript"
echo "   - Docker"
echo "   - GitLens"
echo "   - Prettier"
echo "   - ESLint"
echo ""
echo "3. Configure Git to use Windows line endings:"
echo "   git config --global core.autocrlf true"
echo ""
echo "4. For better performance, consider:"
echo "   - Using WSL2 for development"
echo "   - Excluding project directories from Windows Defender"
echo "   - Using Windows Terminal instead of Git Bash"
echo ""

log_success "Windows environment setup complete!"
