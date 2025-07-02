# VibeBiz Platform Setup Scripts

This directory contains comprehensive setup scripts for the VibeBiz platform. These scripts automate the entire setup process for development and production environments.

## Quick Start

To set up the entire platform, run:

```bash
./tools/setup/setup.sh
```

## Available Scripts

### Main Setup Script

- **`setup.sh`** - Main orchestrator script that runs all setup steps

### OS-Specific Setup

- **`setup-macos.sh`** - macOS-specific setup (Homebrew, Xcode tools)
- **`setup-linux.sh`** - Linux-specific setup (package managers, system dependencies)
- **`setup-windows.sh`** - Windows-specific setup (Chocolatey, WSL detection)

### Individual Setup Steps

- **`check-prerequisites.sh`** - Validates all required tools and dependencies
- **`setup-env.sh`** - Creates and configures environment files
- **`install-dependencies.sh`** - Installs Node.js and Python dependencies
- **`setup-database.sh`** - Sets up PostgreSQL database and runs migrations
- **`setup-security.sh`** - Configures security tools and generates JWT keys
- **`build-packages.sh`** - Builds all packages and applications
- **`setup-tests.sh`** - Sets up and validates the testing environment
- **`health-checks.sh`** - Runs comprehensive health checks

## Usage

### Development Setup

```bash
# Full development setup
./tools/setup/setup.sh

# Skip database setup (useful for CI/CD)
./tools/setup/setup.sh --skip-db

# Skip test setup
./tools/setup/setup.sh --skip-tests

# Verbose output
./tools/setup/setup.sh --verbose
```

### Production Setup

```bash
# Production setup (requires manual configuration)
./tools/setup/setup.sh --production
```

### Individual Steps

You can run individual setup steps if needed:

```bash
# Check prerequisites only
./tools/setup/check-prerequisites.sh

# Setup environment files only
./tools/setup/setup-env.sh

# Install dependencies only
./tools/setup/install-dependencies.sh

# Setup database only
./tools/setup/setup-database.sh

# Setup security only
./tools/setup/setup-security.sh

# Build packages only
./tools/setup/build-packages.sh

# Setup tests only
./tools/setup/setup-tests.sh

# Run health checks only
./tools/setup/health-checks.sh
```

## Prerequisites

Before running the setup scripts, ensure you have:

### Required Tools

- **Git** - Version control
- **Node.js** (>=18.0.0) - JavaScript runtime
- **pnpm** (>=9.0.0) - Package manager
- **Python** (>=3.11) - Python runtime
- **Poetry** - Python dependency management
- **Docker** - Containerization

### Optional Tools

- **Trivy** - Security scanning
- **Gitleaks** - Secret detection
- **Hadolint** - Docker linting
- **jq** - JSON processing
- **pre-commit** - Git hooks

## What the Setup Does

### 1. OS-Specific Setup

- Installs missing system dependencies
- Configures package managers (Homebrew, apt, dnf, etc.)
- Sets up development tools

### 2. Prerequisites Check

- Validates all required tools are installed
- Checks version requirements
- Verifies system resources

### 3. Environment Setup

- Creates `.env` files from examples
- Configures development defaults
- Sets up test environment

### 4. Dependencies Installation

- Installs Node.js dependencies with pnpm
- Installs Python dependencies with Poetry
- Sets up pre-commit hooks

### 5. Database Setup

- Starts PostgreSQL with Docker
- Creates development and test databases
- Runs database migrations
- Seeds initial data (if available)

### 6. Security Setup

- Generates JWT keys
- Configures security tools
- Sets up security headers
- Runs initial security scans

### 7. Package Building

- Builds Node.js packages and applications
- Builds Python packages
- Creates Docker images
- Runs type checking and linting

### 8. Test Setup

- Configures test database
- Sets up test environment
- Validates test dependencies
- Runs initial tests

### 9. Health Checks

- Validates all components
- Tests functionality
- Generates health report

## Environment Files Created

The setup creates the following environment files:

- **`.env`** - Root environment configuration
- **`services/public-api/.env`** - Public API service configuration
- **`apps/public-web/.env.local`** - Public web application configuration
- **`tests/.env.test`** - Test environment configuration

## Troubleshooting

### Common Issues

1. **Docker not running**

   ```bash
   # macOS
   open -a Docker

   # Linux
   sudo systemctl start docker
   ```

2. **Permission issues**

   ```bash
   chmod +x tools/setup/*.sh
   ```

3. **Missing dependencies**

   ```bash
   # Run OS-specific setup first
   ./tools/setup/setup-macos.sh  # or setup-linux.sh, setup-windows.sh
   ```

4. **Database connection issues**

   ```bash
   # Restart PostgreSQL
   docker restart vibebiz-postgres
   ```

5. **Python Externally Managed Environment (PEP 668)**
   - **Error**: `externally-managed-environment`
   - **Cause**: Modern Python installations prevent global package installation
   - **Solution**: The setup scripts automatically handle this by:
     - Using `pipx` for command-line tools (pre-commit, etc.)
     - Using `--user` flag for other packages
     - Using Poetry for project dependencies (which creates virtual environments)
   - **Note**: This is normal on macOS 12+ and modern Linux distributions

6. **Homebrew Installation Issues**
   - If Homebrew installation fails, run: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
   - Add Homebrew to PATH: `echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc`

7. **Xcode Command Line Tools**
   - If Xcode tools installation fails, run: `xcode-select --install`
   - Accept the license: `sudo xcodebuild -license accept`

8. **Cross-Platform Compatibility**
   - The setup scripts automatically detect your operating system
   - Memory and disk space checks work on macOS, Linux, and Windows
   - Package installation methods are optimized for each platform
   - All scripts include proper error handling for platform-specific commands

### Getting Help

- Check the health check report: `health-check-report.txt`
- Review individual script output for specific errors
- Ensure all prerequisites are met before running setup

## Security Notes

- JWT keys are stored in `~/.vibebiz/` with restricted permissions
- Development environment uses non-secure defaults
- Production setup requires manual configuration of secure values
- Never commit `.env` files to version control

## Next Steps

After successful setup:

1. Start development servers: `pnpm dev`
2. Run tests: `./tools/run-all-tests.sh`
3. Access applications:
   - Public Web: <http://localhost:3000>
   - Public API: <http://localhost:8000>
   - API Docs: <http://localhost:8000/docs>

## Contributing

When adding new setup steps:

1. Create a new script in this directory
2. Update the main `setup.sh` script to call it
3. Add appropriate error handling and logging
4. Update this README with usage instructions
5. Test on multiple operating systems
