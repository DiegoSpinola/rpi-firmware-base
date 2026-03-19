#!/bin/bash

# Check if the script is running inside the Alloy environment
if [[ "$CUSTOM_HOSTNAME" != "alloy" ]]; then
  echo "ERROR: This script must be run inside the Alloy environment."
  exit 1
fi

# Check if the registry is reachable
REGISTRY_URL="registry.hackeneering.com"
if ! ping -4 -c 1 "$REGISTRY_URL" > /dev/null; then
  echo "ERROR: The registry $REGISTRY_URL is not reachable. Are you connected to the Igma R&D VPN? If not, request access via the Slack channel."
  exit 1
fi

# Check if Docker client is logged in
if ! docker info > /dev/null 2>&1; then
  echo "ERROR: Docker client is not logged in."
  exit 1
fi

# Build the images
echo "Building the images..."
source ./build.sh

# Get the value of deployable-service from the .config file
SERVICES_TO_DEPLOY=$(jq -r '.["deployable-service"]' .config)

# Check if SERVICES_TO_DEPLOY is empty
if [[ -z "$SERVICES_TO_DEPLOY" ]]; then
  echo "No services to deploy. Exiting..."
  exit 1
fi

# Push the images to the registry
echo "Pushing the images to the registry..."
echo "services to deploy: $SERVICES_TO_DEPLOY" 
docker-compose -f docker-compose.yml push $SERVICES_TO_DEPLOY

echo "Images being pushed:"

# for service in $SERVICES_TO_DEPLOY; do
  # IMG_NAME=$(docker-compose -f docker-compose.yml config | awk -v service_name="$service" '/^    image:.*'"$service_name"'$/ {print $2}')
  # echo "Image being pushed for $service: $IMG_NAME"
  # if [[ "$IMG_NAME" != *WIP ]]; then
    # echo "Tagging $IMG_NAME with the 'latest' tag and pushing..."
    # LATEST_IMAGE_TAG="${IMG_NAME%:*}:latest"
    # echo "image becomes: $LATEST_IMAGE_TAG"
    # docker tag $IMG_NAME $LATEST_IMAGE_TAG
    # docker push $LATEST_IMAGE_TAG
  # fi
# done

for service in $SERVICES_TO_DEPLOY; do
  #IMG_NAME=$(docker-compose -f docker-compose.yml config | awk -v service_name="$service" '/^    image:.*'"$service_name"'$/ {print $2}')
  #IMG_NAME=$(yq ".services[\"${service}\"].image" docker-compose.yml)
  IMG_NAME=$(docker-compose -f docker-compose.yml config | yq -r ".services[\"${service}\"].image")
  if [[ -z "$IMG_NAME" ]]; then
    echo "No image found for $service. Skipping..."
    continue
  fi
  echo "Image being pushed for $service: $IMG_NAME"
  if [[ "$IMG_NAME" != *WIP ]]; then
    echo "	Tagging $IMG_NAME with the 'latest' tag and pushing..."
    LATEST_IMAGE_TAG="${IMG_NAME/${COMMIT_HASH}/latest}"
    echo "	image becomes: $LATEST_IMAGE_TAG"
    docker tag $IMG_NAME $LATEST_IMAGE_TAG
    docker push $LATEST_IMAGE_TAG
  else
	echo "	Image is a WIP, not tagging it with 'latest'"
  fi
done