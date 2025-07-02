#!/bin/bash
#
# VibeBiz Platform Dependency Installation
# This script installs all Node.js and Python dependencies
#

set -e

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

# Function to install Node.js dependencies
install_node_dependencies() {
    log_info "Installing Node.js dependencies..."

    cd "$ROOT_DIR"

    # Check if pnpm is available
    if ! command -v pnpm &> /dev/null; then
        log_error "pnpm is not installed. Please install pnpm first."
        return 1
    fi

    # Install root dependencies
    log_info "Installing root dependencies..."
    if ! pnpm install; then
        log_error "Failed to install root Node.js dependencies"
        return 1
    fi

    log_success "Root Node.js dependencies installed"

    # Install dependencies for each app
    for app_dir in apps/*/; do
        if [ -f "$app_dir/package.json" ]; then
            app_name=$(basename "$app_dir")
            log_info "Installing dependencies for $app_name..."

            cd "$app_dir"
            if ! pnpm install; then
                log_error "Failed to install dependencies for $app_name"
                cd "$ROOT_DIR"
                return 1
            fi
            cd "$ROOT_DIR"

            log_success "Dependencies installed for $app_name"
        fi
    done

    # Install dependencies for each package
    for package_dir in packages/*/; do
        if [ -f "$package_dir/package.json" ]; then
            package_name=$(basename "$package_dir")
            log_info "Installing dependencies for $package_name..."

            cd "$package_dir"
            if ! pnpm install; then
                log_error "Failed to install dependencies for $package_name"
                cd "$ROOT_DIR"
                return 1
            fi
            cd "$ROOT_DIR"

            log_success "Dependencies installed for $package_name"
        fi
    done

    log_success "All Node.js dependencies installed"
}

# Function to install Python dependencies
install_python_dependencies() {
    log_info "Installing Python dependencies..."

    cd "$ROOT_DIR"

    # Check if poetry is available
    if ! command -v poetry &> /dev/null; then
        log_error "Poetry is not installed. Please install Poetry first."
        return 1
    fi

    # Install dependencies for each Python service
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            log_info "Installing Python dependencies for $service_name..."

            cd "$service_dir"

            # Check if virtual environment exists
            if [ ! -d ".venv" ] && [ ! -d "venv" ]; then
                log_info "Creating virtual environment for $service_name..."
                if ! poetry env use python3; then
                    log_error "Failed to create virtual environment for $service_name"
                    cd "$ROOT_DIR"
                    return 1
                fi
            fi

            # Check if lock file needs updating
            if [ -f "poetry.lock" ]; then
                # Try to install first, if it fails due to lock file, regenerate it
                if ! poetry check --lock 2>/dev/null; then
                    log_info "Lock file is out of date, regenerating..."
                    if ! poetry lock; then
                        log_error "Failed to update poetry.lock for $service_name"
                        cd "$ROOT_DIR"
                        return 1
                    fi
                fi
            else
                log_info "No lock file found, generating..."
                if ! poetry lock; then
                    log_error "Failed to generate poetry.lock for $service_name"
                    cd "$ROOT_DIR"
                    return 1
                fi
            fi

            # Now install dependencies
            if ! poetry install --no-root; then
                log_error "Failed to install Python dependencies for $service_name"
                cd "$ROOT_DIR"
                return 1
            fi

            cd "$ROOT_DIR"
            log_success "Python dependencies installed for $service_name"
        fi
    done

    log_success "All Python dependencies installed"
}

# Function to install pre-commit hooks
install_pre_commit_hooks() {
    log_info "Installing pre-commit hooks..."

    cd "$ROOT_DIR"

    if command -v pre-commit &> /dev/null; then
        if [ -f ".pre-commit-config.yaml" ]; then
            if ! pre-commit install; then
                log_warning "Failed to install pre-commit hooks"
            else
                log_success "Pre-commit hooks installed"
            fi
        else
            log_warning "No .pre-commit-config.yaml found"
        fi
    else
        log_warning "pre-commit not installed - skipping hook installation"
    fi
}

# Function to verify installations
verify_installations() {
    log_info "Verifying installations..."

    cd "$ROOT_DIR"

    # Verify Node.js dependencies
    log_info "Verifying Node.js dependencies..."
    if ! pnpm list --depth=0 > /dev/null 2>&1; then
        log_warning "Node.js dependency verification failed"
    else
        log_success "Node.js dependencies verified"
    fi

    # Verify Python dependencies
    log_info "Verifying Python dependencies..."
    for service_dir in services/*/; do
        if [ -f "$service_dir/pyproject.toml" ]; then
            service_name=$(basename "$service_dir")
            cd "$service_dir"

            if poetry show > /dev/null 2>&1; then
                log_success "Python dependencies verified for $service_name"
            else
                log_warning "Python dependency verification failed for $service_name"
            fi

            cd "$ROOT_DIR"
        fi
    done
}

# Function to clean up
cleanup() {
    log_info "Cleaning up temporary files..."

    cd "$ROOT_DIR"

    # Remove node_modules/.cache if it exists
    if [ -d "node_modules/.cache" ]; then
        rm -rf node_modules/.cache
        log_success "Cleaned Node.js cache"
    fi

    # Remove Python cache files
    find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    find . -type f -name "*.pyc" -delete 2>/dev/null || true
    log_success "Cleaned Python cache files"
}

# Main installation function
main() {
    log_info "Starting dependency installation..."

    # Change to root directory
    cd "$ROOT_DIR"

    # Install Node.js dependencies
    if ! install_node_dependencies; then
        log_error "Failed to install Node.js dependencies"
        exit 1
    fi

    # Install Python dependencies
    if ! install_python_dependencies; then
        log_error "Failed to install Python dependencies"
        exit 1
    fi

    # Install pre-commit hooks
    install_pre_commit_hooks

    # Verify installations
    verify_installations

    # Clean up
    cleanup

    log_success "All dependencies installed successfully!"

    echo ""
    log_info "Installation Summary:"
    echo "✅ Node.js dependencies installed"
    echo "✅ Python dependencies installed"
    echo "✅ Pre-commit hooks installed (if available)"
    echo "✅ Dependencies verified"
    echo "✅ Cache cleaned"
    echo ""
    log_info "You can now proceed with the next setup step."
}

# Run main function
main
