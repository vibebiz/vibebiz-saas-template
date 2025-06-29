#!/bin/bash
set -e

# Run all JS/TS tests via turbo
pnpm test

# Run all Python tests via pytest (from repo root)
pytest
