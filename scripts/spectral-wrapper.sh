#!/bin/sh
echo "--- Running Spectral Wrapper ---"

# This script loads environment variables from a .env file if it exists,
# then runs the spectral command with the provided arguments.

if [ -f ".env" ]; then
  echo "Found .env file, loading variables..."
  set -o allexport
  source ./.env
  set +o allexport
  echo "SPECTRAL_DSN is set to: $SPECTRAL_DSN"
else
  echo "No .env file found."
fi

echo "Running spectral lint on files: $@"
# The SPECTRAL_DSN is now available as an environment variable.
# Now, execute the actual spectral command with all the arguments passed to the script.
spectral lint "$@"

echo "--- Spectral Wrapper Finished ---"
