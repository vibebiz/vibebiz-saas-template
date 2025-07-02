#!/bin/bash
#
# Description: Runs fast feedback checks for local development.
# This provides quick validation of code quality, security, and basic functionality.
# For comprehensive testing including E2E tests, use run-comprehensive-tests.sh in CI/CD.
#

set -eo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "🚀 Running fast feedback checks for local development..."
echo "   Note: E2E tests are excluded for speed. Use test:comprehensive for full validation."

pre-commit run --all-files

echo "✅ Fast feedback checks complete."
echo ""
echo "📋 Next steps:"
echo "   - For comprehensive testing: pnpm test:comprehensive"
echo "   - For E2E tests only: pnpm test:e2e"
echo "   - For accessibility tests: pnpm test:accessibility"
