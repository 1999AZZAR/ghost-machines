#!/bin/bash

# Ghost Machines: Smart Snapshot Utility
# Archives workspace mounts with intelligent cache exclusion, SHA-256 checksums,
# and portable metadata.

set -e

OUTPUT_FILE=""
INCLUDE_ALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --all)
            INCLUDE_ALL=true
            shift
            ;;
        -h|--help)
            echo "Ghost Machines — Snapshot Utility"
            echo ""
            echo "Usage: ./snapshot.sh [options]"
            echo ""
            echo "Options:"
            echo "  -o, --output <filename>  Specify output snapshot archive path"
            echo "      --all                Include all transient cache files (no exclusions)"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ ! -d "mounts" ]; then
    echo "[ERROR] Mounts directory not found. Please run from the project root."
    exit 1
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="${OUTPUT_FILE:-ghost_snapshot_$TIMESTAMP.tar.gz}"

echo "------------------------------------------------"
echo " GHOST MACHINES: SNAPSHOT"
echo "------------------------------------------------"
echo "[INFO] Target Archive: $BACKUP_NAME"

EXCLUDES=()
if [ "$INCLUDE_ALL" = false ]; then
    echo "[INFO] Applying smart cache & transient data exclusions..."
    EXCLUDES=(
        --exclude='*/node_modules/.cache'
        --exclude='*/.npm/_cacache'
        --exclude='*/.bun/install/cache'
        --exclude='*/target'
        --exclude='*/.cache'
        --exclude='*/__pycache__'
        --exclude='*/.pytest_cache'
        --exclude='*.tmp'
        --exclude='*.log'
        --exclude='*.DS_Store'
        --exclude='*Thumbs.db'
    )
else
    echo "[INFO] Capturing complete mounts/ directory (including all caches)..."
fi

tar -czf "$BACKUP_NAME" "${EXCLUDES[@]}" mounts/

# Generate SHA-256 Checksum
if command -v sha256sum &> /dev/null; then
    sha256sum "$BACKUP_NAME" > "${BACKUP_NAME}.sha256"
elif command -v shasum &> /dev/null; then
    shasum -a 256 "$BACKUP_NAME" > "${BACKUP_NAME}.sha256"
fi

ARCHIVE_HASH=$(awk '{print $1}' "${BACKUP_NAME}.sha256" 2>/dev/null || echo "unknown")
ARCHIVE_SIZE=$(ls -lh "$BACKUP_NAME" | awk '{print $5}')
TOTAL_FILES=$(find mounts/ -type f | wc -l)

# Generate Metadata Manifest
cat <<EOF > "${BACKUP_NAME}.meta.json"
{
  "snapshot": "$BACKUP_NAME",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "host_arch": "$(uname -m)",
  "host_os": "$(uname -s)",
  "file_count": $TOTAL_FILES,
  "archive_size": "$ARCHIVE_SIZE",
  "sha256": "$ARCHIVE_HASH",
  "smart_cache_exclusion": $([ "$INCLUDE_ALL" = false ] && echo "true" || echo "false")
}
EOF

echo "[SUCCESS] Snapshot created successfully."
echo "[LOCATION] $(pwd)/$BACKUP_NAME"
echo "[CHECKSUM] ${BACKUP_NAME}.sha256 ($ARCHIVE_HASH)"
echo "[METADATA] ${BACKUP_NAME}.meta.json"
