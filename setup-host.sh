#!/bin/bash

# Ghost Machines: Host Setup Script
# Installs and configures LXCFS for accurate container resource reporting across Linux distributions.

set -e

echo "------------------------------------------------"
echo " GHOST MACHINES: HOST ENVIRONMENT SETUP"
echo "------------------------------------------------"

# 1. OS & Platform Check
OS_TYPE="$(uname -s)"
if [ "$OS_TYPE" != "Linux" ]; then
    echo "[INFO] Non-Linux OS detected ($OS_TYPE)."
    echo "[INFO] On macOS or Windows (Docker Desktop/WSL2), LXCFS is not required."
    echo "[INFO] You can proceed directly with './start.sh'."
    exit 0
fi

# 2. Package Manager Detection & Installation
if command -v apt-get &> /dev/null; then
    echo "[INFO] Detected Debian/Ubuntu (apt-get)."
    sudo apt-get update
    sudo apt-get install -y lxcfs
elif command -v pacman &> /dev/null; then
    echo "[INFO] Detected Arch Linux (pacman)."
    sudo pacman -Sy --noconfirm lxcfs
elif command -v dnf &> /dev/null; then
    echo "[INFO] Detected Fedora/RHEL (dnf)."
    sudo dnf install -y lxcfs
elif command -v zypper &> /dev/null; then
    echo "[INFO] Detected openSUSE (zypper)."
    sudo zypper install -y lxcfs
elif command -v apk &> /dev/null; then
    echo "[INFO] Detected Alpine Linux (apk)."
    sudo apk add lxcfs
else
    echo "[WARNING] No supported package manager found."
    echo "[INFO] Please install 'lxcfs' manually using your distribution's package manager."
    exit 1
fi

# 3. Enable and Start LXCFS Service
echo "[INFO] Starting LXCFS service..."
if command -v systemctl &> /dev/null; then
    sudo systemctl enable lxcfs 2>/dev/null || true
    sudo systemctl start lxcfs 2>/dev/null || true
    if systemctl is-active --quiet lxcfs; then
        echo "[SUCCESS] LXCFS is running via systemd."
    else
        echo "[WARNING] LXCFS service is not active under systemctl."
    fi
elif command -v rc-service &> /dev/null; then
    sudo rc-service lxcfs start 2>/dev/null || true
    echo "[SUCCESS] LXCFS started via OpenRC."
elif command -v service &> /dev/null; then
    sudo service lxcfs start 2>/dev/null || true
    echo "[SUCCESS] LXCFS started via init service."
else
    echo "[INFO] LXCFS installed. If needed, start it manually in background: sudo lxcfs /var/lib/lxcfs &"
fi

echo "------------------------------------------------"
echo "[SUCCESS] Host setup complete. You can now run './start.sh'."
echo "------------------------------------------------"
