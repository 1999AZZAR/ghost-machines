#!/bin/bash

# Ghost Machines: Host Setup Script
# This script installs and configures LXCFS for accurate container resource reporting.

set -e

# OS Compatibility Check
if ! command -v apt-get &> /dev/null; then
    echo "[ERROR] This script requires 'apt-get' (Debian/Ubuntu)."
    echo "[INFO] If you are on macOS or another Linux distribution, please refer to the README for manual LXCFS setup."
    exit 1
fi

echo "Starting host configuration..."

# 1. Update package list
sudo apt-get update

# 2. Install LXCFS
echo "Installing LXCFS..."
sudo apt-get install -y lxcfs

# 3. Enable and Start LXCFS service
echo "Configuring LXCFS service..."
sudo systemctl enable lxcfs
sudo systemctl start lxcfs

# 4. Verify installation
if systemctl is-active --quiet lxcfs; then
    echo "LXCFS is installed and running."
else
    echo "Error: LXCFS failed to start."
    exit 1
fi

echo "Host setup complete. You can now run './start.sh'."
