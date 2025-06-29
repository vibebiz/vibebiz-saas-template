#!/bin/bash
#
# Description: Runs all pre-commit hooks against all files in the repository.
# This provides a way to manually trigger a comprehensive check of the entire codebase.
#

set -eo pipefail

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

echo "\[INFO\] Running all pre-commit hooks on all files..."

pre-commit run --all-files

echo "\[INFO\] All checks complete."
