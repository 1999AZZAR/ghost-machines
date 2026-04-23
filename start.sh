#!/bin/bash

# Ghost Machines: Intelligent Entry Point
# Automatically detects LXCFS and configures volume mounts accordingly.

export LXCFS_BASE="/var/lib/lxcfs/proc"

if [ -d "$LXCFS_BASE" ]; then
    echo "LXCFS detected. Enabling hardware reporting mounts."
    export LXCFS_CPUINFO="$LXCFS_BASE/cpuinfo"
    export LXCFS_MEMINFO="$LXCFS_BASE/meminfo"
    export LXCFS_STAT="$LXCFS_BASE/stat"
    export LXCFS_SWAPS="$LXCFS_BASE/swaps"
    export LXCFS_UPTIME="$LXCFS_BASE/uptime"
else
    echo "LXCFS not detected. Proceeding with standard mounts."
    # Defaults to /dev/null via docker-compose.yml interpolation
fi

docker compose up -d "$@"
