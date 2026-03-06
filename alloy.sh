#!/bin/bash
# alloy run

# Customizable parameters
# SSH_KEY_PATH="/root/.ssh/ghkey" #new versions of alloy will automatically retrieve your keys via the VPN
CONTAINER_NAME="alloy-container"
ALLOY_VERSION="latest" 
IMG_NAME="registry.igmify.com/igma/rd/alloy:$ALLOY_VERSION"

# Error message functions
error() {
  echo -e "\033[1;31mERROR: $@\033[0m"
}

abort() {
  error "$@"
  exit 1
}

# Check if Docker is installed and accessible
if ! command -v docker >/dev/null 2>&1; then
  abort "Docker is not installed or not in the PATH. Please install Docker first."
fi

# Check if the Docker daemon is running
if ! docker info >/dev/null 2>&1; then
  abort "Docker daemon is not running. Please start the Docker daemon before running this script."
fi

# Get the current project path and directory name
PROJECT_PATH=$(pwd)
DIR_NAME=$(basename $PROJECT_PATH)

# Check if the container name is unique
if docker ps -a --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
  abort "Another container with the name '$CONTAINER_NAME' already exists. Please choose a unique container name."
fi

# Start the Alloy container with the project path mounted under /root/<current_directory_name>
# and automatically change the working directory to the mounted project path
#docker run -it --rm --name $CONTAINER_NAME -v $PROJECT_PATH:/root/$DIR_NAME/ $SSH_KEY_MOUNT -v /var/run/docker.sock:/var/run/docker.sock -w /root/$DIR_NAME/ alloy
docker pull $IMG_NAME && docker run --cap-add=NET_ADMIN -it --rm --name $CONTAINER_NAME -v $PROJECT_PATH:/root/$DIR_NAME/ -v /var/run/docker.sock:/var/run/docker.sock -v /etc/docker/:/etc/docker/ -w /root/$DIR_NAME/ $IMG_NAME 
