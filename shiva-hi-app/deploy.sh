#!/usr/bin/env bash
set -e

IMAGE="shivasarla2398/sample-python-app:latest"
CONTAINER="sample-python-app"

echo "Stopping old container if present..."
docker rm -f ${CONTAINER} || true

echo "Pulling latest image..."
docker pull ${IMAGE}

echo "Starting container..."
docker run -d --name ${CONTAINER} -p 80:8000 --restart unless-stopped ${IMAGE}

echo "Done — container started and mapped to host port 80"
