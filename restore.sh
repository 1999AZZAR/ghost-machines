#!/bin/bash

# Ghost Machines: Restore Utility
# Restores the workspace state from a snapshot archive.

echo "------------------------------------------------"
echo " GHOST MACHINES: RESTORE"
echo "------------------------------------------------"

if [ -z "$1" ]; then
    echo "Usage: ./restore.sh <snapshot_file.tar.gz>"
    echo "Available snapshots:"
    ls ghost_snapshot_*.tar.gz 2>/dev/null || echo "  (No snapshots found)"
    exit 1
fi

SNAPSHOT=$1

if [ ! -f "$SNAPSHOT" ]; then
    echo "[ERROR] Snapshot file '$SNAPSHOT' not found."
    exit 1
fi

read -p "[WARNING] This will overwrite your current mounts/ directory. Continue? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

echo "[INFO] Restoring from $SNAPSHOT..."
# Remove current mounts to ensure a clean restore
rm -rf mounts/
tar -xzf "$SNAPSHOT"

if [ $? -eq 0 ]; then
    echo "[SUCCESS] Workspace state restored successfully."
    echo "[NOTE] Run ./start.sh to launch the environments with the restored data."
else
    echo "[ERROR] Restore failed."
    exit 1
fi
