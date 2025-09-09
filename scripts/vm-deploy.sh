#!/bin/bash

# Vagrant deployment script for My Scratch Pad
# Provisions and runs the VM-based application

set -e

echo "=== Vagrant Deployment Script ==="
echo "Deploying My Scratch Pad VM"

# Detect architecture and inform user
if [ "$(uname -m)" = "arm64" ]; then
    echo "Apple Silicon detected - VirtualBox will run x86 VM via emulation"
    echo "This provides excellent performance comparison vs native ARM64 containers"
else
    echo "Intel Mac detected - using native x86 virtualization"
fi

echo ""

# Check if VM is already running
if vagrant status | grep -q "running"; then
    echo "VM is already running. Destroying for fresh deployment..."
    vagrant destroy -f
fi

# Start deployment timer
START_TIME=$(date +%s.%N)

# Bring up the VM
echo "Starting VM deployment..."
vagrant up

# Wait for application to be ready
echo "Waiting for application to be ready..."
timeout=60
counter=0
while [ $counter -lt $timeout ]; do
    if curl -f http://localhost:5001 >/dev/null 2>&1; then
        END_TIME=$(date +%s.%N)
        DEPLOY_TIME=$(echo "$END_TIME - $START_TIME" | bc)
        echo "VM deployment completed in ${DEPLOY_TIME} seconds"
        break
    fi
    sleep 2
    counter=$((counter + 2))
done

if [ $counter -ge $timeout ]; then
    echo "VM failed to respond within ${timeout} seconds"
    echo "Checking VM status..."
    vagrant status
    echo ""
    echo "VM logs:"
    vagrant ssh -c "tail -20 /home/vagrant/my-scratch-pad/app.log" 2>/dev/null || echo "No application logs found"
    exit 1
fi

echo ""
echo "=== Deployment Successful ==="
echo "VM Status: Running"
echo "URL: http://localhost:5001"
echo ""
echo "Useful commands:"
echo "  SSH to VM: vagrant ssh"
echo "  Check VM status: vagrant status"
echo "  Stop VM: vagrant halt"
echo "  Destroy VM: vagrant destroy"
echo "  View app logs: vagrant ssh -c 'tail -f /home/vagrant/my-scratch-pad/app.log'"
echo ""
echo "VM System Information:"
vagrant ssh -c "echo '=== CPU Info ==='; lscpu | grep -E 'Model name|CPU\\(s\\)|Thread|Core'; echo ''; echo '=== Memory Info ==='; free -h; echo ''; echo '=== Disk Info ==='; df -h /" 2>/dev/null || echo "Could not retrieve system info"