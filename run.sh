#!/bin/bash

# Check if the script is running inside the Alloy environment
if [[ "$CUSTOM_HOSTNAME" != "alloy" ]]; then
  echo "ERROR: This script must be run inside the Alloy environment."
  exit 1
fi

# Run the demo webserver
docker-compose down
source ./build.sh
echo $COMMIT_HASH
docker-compose up -d --build

