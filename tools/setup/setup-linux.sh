#!/bin/bash
#
# VibeBiz Platform Setup Script - Linux
# This script sets up the Linux environment for VibeBiz development
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

log_info "Setting up Linux environment..."

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif command -v lsb_release &> /dev/null; then
        lsb_release -si | tr '[:upper:]' '[:lower:]'
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
log_info "Detected distribution: $DISTRO"

# Function to install packages based on distribution
install_packages() {
    local packages="$1"

    case "$DISTRO" in
        ubuntu|debian|linuxmint)
            log_info "Installing packages with apt..."
            sudo apt update
            sudo apt install -y $packages
            ;;
        fedora|rhel|centos|rocky|almalinux)
            log_info "Installing packages with dnf..."
            sudo dnf install -y $packages
            ;;
        arch|manjaro)
            log_info "Installing packages with pacman..."
            sudo pacman -Syu --noconfirm $packages
            ;;
        *)
            log_error "Unsupported distribution: $DISTRO"
            log_info "Please install the following packages manually:"
            echo "  $packages"
            return 1
            ;;
    esac
}

# Install system dependencies
log_info "Installing system dependencies..."

case "$DISTRO" in
    ubuntu|debian|linuxmint)
        install_packages "curl wget git build-essential python3 python3-pip python3-venv"
        ;;
    fedora|rhel|centos|rocky|almalinux)
        install_packages "curl wget git gcc python3 python3-pip"
        ;;
    arch|manjaro)
        install_packages "curl wget git base-devel python python-pip"
        ;;
esac

# Install Node.js
if ! command -v node &> /dev/null; then
    log_info "Installing Node.js..."

    # Download Node.js setup script to a temporary file
    TEMP_SCRIPT=$(mktemp)
    log_info "Downloading Node.js setup script..."

    if curl -fsSL https://deb.nodesource.com/setup_20.x -o "$TEMP_SCRIPT"; then
        # Verify the script is not empty and contains expected content
        if [ -s "$TEMP_SCRIPT" ] && grep -q "NodeSource" "$TEMP_SCRIPT"; then
            log_info "Executing Node.js setup script..."
            sudo -E bash "$TEMP_SCRIPT"
            sudo apt-get install -y nodejs
            rm -f "$TEMP_SCRIPT"
        else
            log_error "Downloaded script appears to be invalid"
            rm -f "$TEMP_SCRIPT"
            exit 1
        fi
    else
        log_error "Failed to download Node.js setup script"
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi

    log_success "Node.js installed"
else
    log_info "Node.js already installed"
fi

# Install pnpm
if ! command -v pnpm &> /dev/null; then
    log_info "Installing pnpm..."

    # Download pnpm install script to a temporary file
    TEMP_SCRIPT=$(mktemp)
    log_info "Downloading pnpm install script..."

    if curl -fsSL https://get.pnpm.io/install.sh -o "$TEMP_SCRIPT"; then
        # Verify the script is not empty and contains expected content
        if [ -s "$TEMP_SCRIPT" ] && grep -q "pnpm" "$TEMP_SCRIPT"; then
            log_info "Executing pnpm install script..."
            sh "$TEMP_SCRIPT"
            export PNPM_HOME="$HOME/.local/share/pnpm"
            export PATH="$PNPM_HOME:$PATH"
            rm -f "$TEMP_SCRIPT"
        else
            log_error "Downloaded script appears to be invalid"
            rm -f "$TEMP_SCRIPT"
            exit 1
        fi
    else
        log_error "Failed to download pnpm install script"
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi

    log_success "pnpm installed"
else
    log_info "pnpm already installed"
fi

# Install Poetry
if ! command -v poetry &> /dev/null; then
    log_info "Installing Poetry..."

    # Download Poetry install script to a temporary file
    TEMP_SCRIPT=$(mktemp)
    log_info "Downloading Poetry install script..."

    if curl -sSL https://install.python-poetry.org -o "$TEMP_SCRIPT"; then
        # Verify the script is not empty and contains expected content
        if [ -s "$TEMP_SCRIPT" ] && grep -q "poetry" "$TEMP_SCRIPT"; then
            log_info "Executing Poetry install script..."
            python3 "$TEMP_SCRIPT"
            export PATH="$HOME/.local/bin:$PATH"
            rm -f "$TEMP_SCRIPT"
        else
            log_error "Downloaded script appears to be invalid"
            rm -f "$TEMP_SCRIPT"
            exit 1
        fi
    else
        log_error "Failed to download Poetry install script"
        rm -f "$TEMP_SCRIPT"
        exit 1
    fi

    log_success "Poetry installed"
else
    log_info "Poetry already installed"
fi

# Install Docker
if ! command -v docker &> /dev/null; then
    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    log_success "Docker installed"
    log_warning "Please log out and back in for Docker group changes to take effect"
else
    log_info "Docker already installed"
fi

# Install security tools
install_security_tools() {
    # Install Trivy
    if ! command -v trivy &> /dev/null; then
        log_info "Installing Trivy..."

        # Download Trivy install script to a temporary file
        TEMP_SCRIPT=$(mktemp)
        log_info "Downloading Trivy install script..."

        if curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh -o "$TEMP_SCRIPT"; then
            # Verify the script is not empty and contains expected content
            if [ -s "$TEMP_SCRIPT" ] && grep -q "trivy" "$TEMP_SCRIPT"; then
                log_info "Executing Trivy install script..."
                sh "$TEMP_SCRIPT" -s -- -b /usr/local/bin
                rm -f "$TEMP_SCRIPT"
            else
                log_error "Downloaded script appears to be invalid"
                rm -f "$TEMP_SCRIPT"
                return 1
            fi
        else
            log_error "Failed to download Trivy install script"
            rm -f "$TEMP_SCRIPT"
            return 1
        fi

        log_success "Trivy installed"
    else
        log_info "Trivy already installed"
    fi

    # Install Gitleaks
    if ! command -v gitleaks &> /dev/null; then
        log_info "Installing Gitleaks..."

        # Download Gitleaks install script to a temporary file
        TEMP_SCRIPT=$(mktemp)
        log_info "Downloading Gitleaks install script..."

        if curl -sSfL https://raw.githubusercontent.com/zricethezav/gitleaks/master/install.sh -o "$TEMP_SCRIPT"; then
            # Verify the script is not empty and contains expected content
            if [ -s "$TEMP_SCRIPT" ] && grep -q "gitleaks" "$TEMP_SCRIPT"; then
                log_info "Executing Gitleaks install script..."
                sh "$TEMP_SCRIPT" -s -- -b /usr/local/bin
                rm -f "$TEMP_SCRIPT"
            else
                log_error "Downloaded script appears to be invalid"
                rm -f "$TEMP_SCRIPT"
                return 1
            fi
        else
            log_error "Failed to download Gitleaks install script"
            rm -f "$TEMP_SCRIPT"
            return 1
        fi

        log_success "Gitleaks installed"
    else
        log_info "Gitleaks already installed"
    fi

    # Install Hadolint
    if ! command -v hadolint &> /dev/null; then
        log_info "Installing Hadolint..."
        curl -L -o hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64
        sudo chmod +x hadolint
        sudo mv hadolint /usr/local/bin/
        log_success "Hadolint installed"
    else
        log_info "Hadolint already installed"
    fi
}

install_security_tools

# Install additional development tools
log_info "Installing additional development tools..."

# Install jq
if ! command -v jq &> /dev/null; then
    install_packages "jq"
fi

# Install pre-commit
if ! command -v pre-commit &> /dev/null; then
    log_info "Installing pre-commit..."
    # Try pipx first, then fallback to pip --user
    if command -v pipx &> /dev/null; then
        pipx install pre-commit
        log_success "pre-commit installed with pipx"
    else
        # Try to install pipx first
        if python3 -m pip install --user pipx; then
            export PATH="$HOME/.local/bin:$PATH"
            pipx install pre-commit
            log_success "pre-commit installed with pipx"
        else
            # Fallback to direct pip install
            if python3 -m pip install --user pre-commit; then
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

# Check if Docker is running
if ! docker info &> /dev/null; then
    log_warning "Docker is not running. Please start Docker and try again."
    log_info "You can start Docker with:"
    echo "  sudo systemctl start docker"
    echo "  sudo systemctl enable docker"
fi

# Add PATH to shell profile
SHELL_PROFILE=""
if [ -f "$HOME/.bashrc" ]; then
    SHELL_PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.zshrc" ]; then
    SHELL_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.profile" ]; then
    SHELL_PROFILE="$HOME/.profile"
fi

if [ -n "$SHELL_PROFILE" ]; then
    # Add PATH exports if not already present
    if ! grep -q "PNPM_HOME" "$SHELL_PROFILE"; then
        echo 'export PNPM_HOME="$HOME/.local/share/pnpm"' >> "$SHELL_PROFILE"
        echo 'export PATH="$PNPM_HOME:$PATH"' >> "$SHELL_PROFILE"
    fi

    if ! grep -q "poetry" "$SHELL_PROFILE"; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_PROFILE"
    fi

    log_info "PATH exports added to $SHELL_PROFILE"
    log_warning "Please source $SHELL_PROFILE or restart your terminal"
fi

log_success "Linux environment setup complete!"
