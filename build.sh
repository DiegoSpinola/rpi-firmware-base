#!/bin/bash

# Check if the script is running inside the Alloy environment
if [[ "$CUSTOM_HOSTNAME" != "alloy" ]]; then
  echo "ERROR: This script must be run inside the Alloy environment."
  exit 1
fi

# Check if the repository state is clean
if [[ -n $(git status -s) ]]; then
  COMMIT_HASH="WIP"
else
  COMMIT_HASH=$(git rev-parse --short HEAD)  # Use short git hash
fi

# Export the COMMIT_HASH environment variable
export COMMIT_HASH

echo "Image will be built with the following tag $COMMIT_HASH"

# Build the demo webserver
docker-compose build --build-arg COMMIT_HASH=${COMMIT_HASH}
