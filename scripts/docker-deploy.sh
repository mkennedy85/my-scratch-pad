#!/bin/bash

# Docker deployment script for My Scratch Pad
# Builds and runs the containerized application

set -e

CONTAINER_NAME="my-scratch-pad"
IMAGE_NAME="my-scratch-pad:latest"
PORT=5001

echo "=== Docker Deployment Script ==="
echo "Building and deploying My Scratch Pad container"
echo ""

# Stop and remove existing container if running
if docker ps -a --format 'table {{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping existing container..."
    docker stop ${CONTAINER_NAME} 2>/dev/null || true
    docker rm ${CONTAINER_NAME} 2>/dev/null || true
fi

# Remove existing image to ensure fresh build
if docker images --format 'table {{.Repository}}:{{.Tag}}' | grep -q "^${IMAGE_NAME}$"; then
    echo "Removing existing image for fresh build..."
    docker rmi ${IMAGE_NAME} 2>/dev/null || true
fi

# Build the Docker image
echo "Building Docker image..."
START_BUILD=$(date +%s.%N)
docker build -t ${IMAGE_NAME} .
END_BUILD=$(date +%s.%N)
BUILD_TIME=$(echo "$END_BUILD - $START_BUILD" | bc)
echo "Build completed in ${BUILD_TIME} seconds"
echo ""

# Run the container
echo "Starting container..."
START_RUN=$(date +%s.%N)
docker run -d \
    --name ${CONTAINER_NAME} \
    -p ${PORT}:${PORT} \
    --memory="256m" \
    --cpus="1.0" \
    ${IMAGE_NAME}

# Wait for container to be healthy
echo "Waiting for container to be ready..."
timeout=30
counter=0
while [ $counter -lt $timeout ]; do
    if curl -f http://localhost:${PORT} >/dev/null 2>&1; then
        END_RUN=$(date +%s.%N)
        RUN_TIME=$(echo "$END_RUN - $START_RUN" | bc)
        echo "Container ready in ${RUN_TIME} seconds"
        break
    fi
    sleep 1
    counter=$((counter + 1))
done

if [ $counter -eq $timeout ]; then
    echo "Container failed to start within ${timeout} seconds"
    docker logs ${CONTAINER_NAME}
    exit 1
fi

echo ""
echo "=== Deployment Successful ==="
echo "Container: ${CONTAINER_NAME}"
echo "Image: ${IMAGE_NAME}"
echo "URL: http://localhost:${PORT}"
echo ""
echo "Useful commands:"
echo "  View logs: docker logs ${CONTAINER_NAME}"
echo "  Stop container: docker stop ${CONTAINER_NAME}"
echo "  Remove container: docker rm ${CONTAINER_NAME}"
echo "  Container stats: docker stats ${CONTAINER_NAME}"