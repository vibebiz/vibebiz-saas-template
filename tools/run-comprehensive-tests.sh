#!/bin/bash
#
# Description: Runs comprehensive tests including E2E tests for CI/CD environments.
# This script is designed for environments where infrastructure can be properly managed.
# For local development, use run-all-checks.sh for fast feedback.
#

set -eo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "🚀 Running comprehensive test suite for CI/CD environment..."

# Set CI environment variables for better test behavior
export CI=true
export NODE_ENV=test

# Step 1: Run fast feedback tests first (fail fast)
echo "📋 Step 1: Running fast feedback tests..."
pnpm test
pnpm test:unit
pnpm test:integration

# Step 2: Run Python tests
echo "🐍 Step 2: Running Python backend tests..."
pytest

# Step 3: Run cross-cutting tests (security, performance)
echo "🔒 Step 3: Running cross-cutting tests..."
pnpm test:cross-cutting
pnpm test:security
pnpm test:performance

# Step 4: Run E2E tests with proper infrastructure
echo "🌐 Step 4: Running E2E tests..."
echo "   Note: E2E tests require running servers and may take several minutes"
pnpm test:e2e

# Step 5: Run accessibility tests
echo "♿ Step 5: Running accessibility tests..."
pnpm test:accessibility

echo "✅ Comprehensive test suite completed successfully!"
echo ""
echo "📊 Test Summary:"
echo "   - Package-local tests: ✅"
echo "   - Python backend tests: ✅"
echo "   - Cross-cutting tests: ✅"
echo "   - E2E tests: ✅"
echo "   - Accessibility tests: ✅"
echo ""
echo "🎯 All tests passed! Ready for deployment."
