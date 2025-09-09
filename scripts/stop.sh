#!/bin/bash

# Stop script for My Scratch Pad
# Stops both Docker containers and Vagrant VMs

set -e

echo "=== My Scratch Pad Stop Script ==="
echo "Stopping all running instances..."
echo ""

# Stop Docker container
echo "Stopping Docker container..."
if docker ps | grep -q my-scratch-pad; then
    docker stop my-scratch-pad
    docker rm my-scratch-pad
    echo "✓ Docker container stopped and removed"
else
    echo "- No Docker container running"
fi

echo ""

# Stop Vagrant VM
echo "Stopping Vagrant VM..."
if vagrant status | grep -q "running"; then
    vagrant halt
    echo "✓ Vagrant VM stopped"
else
    echo "- No Vagrant VM running"
fi

echo ""
echo "=== All instances stopped ==="
echo ""
echo "To completely remove VMs:"
echo "  vagrant destroy    # Remove VM completely"
echo ""
echo "To restart:"
echo "  ./scripts/docker-deploy.sh    # Start Docker container"
echo "  ./scripts/vm-deploy.sh        # Start Vagrant VM"