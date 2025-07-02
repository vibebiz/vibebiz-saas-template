#!/bin/bash
#
# VibeBiz Platform Setup Script - macOS
# This script sets up the macOS environment for VibeBiz development
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

log_info "Setting up macOS environment..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    log_info "Installing Homebrew..."

    # Download Homebrew install script to a temporary file
    TEMP_SCRIPT=$(mktemp)
    log_info "Downloading Homebrew install script..."

    if curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$TEMP_SCRIPT"; then
        # Verify the script is not empty and contains expected content
        if [ -s "$TEMP_SCRIPT" ] && grep -q "Homebrew" "$TEMP_SCRIPT"; then
            log_info "Executing Homebrew install script..."
            /bin/bash "$TEMP_SCRIPT"
            rm -f "$TEMP_SCRIPT"
        else
            log_error "Downloaded script appears to be invalid"
            rm -f "$TEMP_SCRIPT"
            exit 1
        fi
    else
        log_error "Failed to download Homebrew install script"
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi

    # Add Homebrew to PATH for Apple Silicon Macs
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    log_success "Homebrew installed"
else
    log_success "Homebrew already installed"
fi

# Function to install a tool with Homebrew if missing
install_with_brew() {
    local tool_name="$1"
    local brew_pkg_name="${2:-$1}"
    local version_check="${3:-}"

    if ! command -v "$tool_name" &> /dev/null; then
        log_info "Installing $tool_name with Homebrew..."
        brew install "$brew_pkg_name"
        log_success "$tool_name installed"
    else
        if [ -n "$version_check" ]; then
            local current_version=$($tool_name $version_check 2>/dev/null | head -n1 || echo "")
            log_info "$tool_name already installed (version: $current_version)"
        else
            log_info "$tool_name already installed"
        fi
    fi
}

# Install required tools
log_info "Installing required tools..."

# Node.js and pnpm
install_with_brew node "node@20" "--version"
install_with_brew pnpm "pnpm" "--version"

# Python and Poetry
install_with_brew python "python@3.12" "--version"
install_with_brew poetry "poetry" "--version"

# Docker
install_with_brew docker "docker" "--version"

# Security tools
install_with_brew trivy "trivy" "--version"
install_with_brew gitleaks "gitleaks" "--version"
install_with_brew hadolint "hadolint" "--version"

# Development tools
install_with_brew git "git" "--version"
install_with_brew jq "jq" "--version"

# Install Xcode Command Line Tools if not already installed
if ! xcode-select -p &> /dev/null; then
    log_info "Installing Xcode Command Line Tools..."
    xcode-select --install
    log_success "Xcode Command Line Tools installed"
else
    log_success "Xcode Command Line Tools already installed"
fi

# Install additional Python packages that might be needed
log_info "Installing additional Python packages..."

# Check if pipx is already installed via Homebrew
if ! command -v pipx &> /dev/null; then
    log_info "Installing pipx with Homebrew..."
    brew install pipx
    # Add pipx to PATH
    export PATH="$HOME/.local/bin:$PATH"
fi

# Install pre-commit if not already installed
if ! command -v pre-commit &> /dev/null; then
    log_info "Installing pre-commit with pipx..."
    pipx install pre-commit
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
    log_info "You can start Docker Desktop from Applications or run:"
    echo "  open -a Docker"
fi

log_success "macOS environment setup complete!"
