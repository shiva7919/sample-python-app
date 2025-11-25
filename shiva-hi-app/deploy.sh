#!/usr/bin/env bash
set -e

IMAGE="your-dockerhub-username/shiva-hi-app:latest"
CONTAINER="shiva-hi-app"

echo "Stopping old container if present..."
docker rm -f ${CONTAINER} || true

echo "Pulling latest image..."
docker pull ${IMAGE}

echo "Starting container..."
docker run -d --name ${CONTAINER} -p 80:8000 --restart unless-stopped ${IMAGE}

echo "Done, container started."
