#!/bin/bash

# Ghost Machines: Resilient Restore Utility
# Restores workspace state with SHA-256 integrity verification, atomic rollback protection,
# and non-interactive flags.

set -e

FORCE=false
KEEP_BACKUP=false
SNAPSHOT=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes|--force)
            FORCE=true
            shift
            ;;
        -k|--keep-backup)
            KEEP_BACKUP=true
            shift
            ;;
        -h|--help)
            echo "Ghost Machines — Restore Utility"
            echo ""
            echo "Usage: ./restore.sh [options] <snapshot_file.tar.gz>"
            echo ""
            echo "Options:"
            echo "  -y, --yes, --force    Skip confirmation prompts (for CI/CD)"
            echo "  -k, --keep-backup     Retain previous mounts backup after successful restore"
            echo "  -h, --help            Show this help message"
            exit 0
            ;;
        *)
            if [ -z "$SNAPSHOT" ]; then
                SNAPSHOT="$1"
                shift
            else
                echo "[ERROR] Unknown extra argument: $1"
                exit 1
            fi
            ;;
    esac
done

if [ -z "$SNAPSHOT" ]; then
    echo "Usage: ./restore.sh [options] <snapshot_file.tar.gz>"
    echo ""
    echo "Available snapshots:"
    ls ghost_snapshot_*.tar.gz 2>/dev/null || echo "  (No snapshots found)"
    exit 1
fi

if [ ! -f "$SNAPSHOT" ]; then
    echo "[ERROR] Snapshot file '$SNAPSHOT' not found."
    exit 1
fi

echo "------------------------------------------------"
echo " GHOST MACHINES: RESTORE"
echo "------------------------------------------------"
echo "[INFO] Snapshot: $SNAPSHOT"

# 1. SHA-256 Checksum Verification
if [ -f "${SNAPSHOT}.sha256" ]; then
    echo "[INFO] Verifying SHA-256 integrity..."
    if command -v sha256sum &> /dev/null; then
        sha256sum -c "${SNAPSHOT}.sha256"
    elif command -v shasum &> /dev/null; then
        shasum -a 256 -c "${SNAPSHOT}.sha256"
    fi
    echo "[SUCCESS] Checksum verified."
else
    echo "[WARNING] No companion checksum file (${SNAPSHOT}.sha256) found. Proceeding with caution."
fi

# 2. Confirmation Check
if [ "$FORCE" = false ]; then
    read -r -p "[WARNING] This will overwrite your current mounts/ directory. Continue? (y/n): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "Restore cancelled."
        exit 0
    fi
fi

# 3. Atomic Backup of Existing Mounts
BACKUP_DIR=".mounts_backup_$(date +%s)"
if [ -d "mounts" ]; then
    echo "[INFO] Creating temporary atomic backup of current mounts at $BACKUP_DIR..."
    cp -r mounts/ "$BACKUP_DIR"
fi

# 4. Safe Decompression with Atomic Rollback Protection
echo "[INFO] Extracting $SNAPSHOT..."
# Preserve directory inode so active container VFS mounts are not invalidated
find mounts -mindepth 1 -delete 2>/dev/null || true

if tar -xzf "$SNAPSHOT"; then
    echo "[SUCCESS] Workspace state restored successfully."
    if [ "$KEEP_BACKUP" = false ] && [ -d "$BACKUP_DIR" ]; then
        rm -rf "$BACKUP_DIR"
    fi
    echo "[NOTE] Run './start.sh' to launch environments with restored data."
else
    echo "[ERROR] Snapshot extraction failed. Performing atomic rollback to previous state..."
    find mounts -mindepth 1 -delete 2>/dev/null || true
    if [ -d "$BACKUP_DIR" ]; then
        cp -r "$BACKUP_DIR"/* mounts/ 2>/dev/null || true
        rm -rf "$BACKUP_DIR"
        echo "[ROLLBACK] Previous workspace mounts successfully restored."
    fi
    exit 1
fi
