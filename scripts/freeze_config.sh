#!/bin/bash

# This script freezes or unfreezes critical configuration files to prevent
# unintentional changes. Use with 'freeze' or 'unfreeze' as the first argument.

set -euo pipefail

CONFIG_FILES=(
  ".pre-commit-config.yaml"
  ".spectral.yaml"
  "eslint.config.js"
  ".gitleaks.toml"
  ".markdownlint.json"
  "commitlint.config.js"
  "jest.config.js"
  "pyproject.toml"
  "tsconfig.json"
  "turbo.json"
  "package.json"
  "pnpm-lock.yaml"
  "pnpm-workspace.yaml"
  ".github/workflows/enforce-main-source.yml"
  ".github/workflows/test.yml"
)

ACTION=${1:-""}

if [[ "$ACTION" != "freeze" && "$ACTION" != "unfreeze" ]]; then
  echo "Usage: $0 {freeze|unfreeze}" >&2
  exit 1
fi

# Get the directory of the script
SCRIPT_DIR=$(dirname "$0")

# Go to the project root
cd "$SCRIPT_DIR/.."

for file in "${CONFIG_FILES[@]}"; do
  if [ -f "$file" ]; then
    if [[ "$ACTION" == "freeze" ]]; then
      echo "Freezing $file..."
      chmod u-w "$file"
    elif [[ "$ACTION" == "unfreeze" ]]; then
      echo "Unfreezing $file..."
      chmod u+w "$file"
    fi
  else
    echo "Warning: $file not found, skipping." >&2
  fi
done

echo "Operation '$ACTION' completed successfully."
