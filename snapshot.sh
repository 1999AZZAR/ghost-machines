#!/bin/bash

# Ghost Machines: Snapshot Utility
# Archives the current state of all container mounts.

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ghost_snapshot_$TIMESTAMP.tar.gz"

echo "------------------------------------------------"
echo " GHOST MACHINES: SNAPSHOT"
echo "------------------------------------------------"

if [ ! -d "mounts" ]; then
    echo "[ERROR] Mounts directory not found. Are you in the project root?"
    exit 1
fi

echo "[INFO] Creating snapshot: $BACKUP_NAME..."
# Exclude potential socket files or large temp data if necessary
tar -czf "$BACKUP_NAME" mounts/

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Snapshot created successfully."
    echo "[LOCATION] $(pwd)/$BACKUP_NAME"
else
    echo "[ERROR] Snapshot failed."
    exit 1
fi
