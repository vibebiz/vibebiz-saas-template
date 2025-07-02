#!/bin/bash
#
# This script starts the development server for the VibeBiz SaaS template.
# It ensures all dependencies are installed and then starts the frontend and backend
# services concurrently with hot-reloading.

set -e # Exit immediately if a command exits with a non-zero status.

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to the project root
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Inform the user what's happening
echo "🚀 Starting development server..."

# Step 1: Install dependencies using pnpm
# This ensures all workspace dependencies are correctly linked.
echo "📦 Installing dependencies..."
pnpm install

# Step 2: Start the development servers using Turbo
# This command runs the 'dev' script in all workspaces (apps and services)
# in parallel. It enables hot-reloading for a seamless development experience.
echo "🔥 Firing up the dev server with hot-reloading..."
pnpm turbo run dev --parallel

echo "✅ Development server is up and running!"
