#!/bin/bash

# Ghost Machines: Intelligent Entry Point
# Supports multiple deployment modes and automated hardware detection.

# 1. LXCFS Detection
export LXCFS_BASE="/var/lib/lxcfs/proc"
if [ -d "$LXCFS_BASE" ]; then
    echo "[INFO] LXCFS detected. Enabling hardware reporting mounts."
    export LXCFS_CPUINFO="$LXCFS_BASE/cpuinfo"
    export LXCFS_MEMINFO="$LXCFS_BASE/meminfo"
    export LXCFS_STAT="$LXCFS_BASE/stat"
    export LXCFS_SWAPS="$LXCFS_BASE/swaps"
    export LXCFS_UPTIME="$LXCFS_BASE/uptime"
fi

# 2. Host Resource Calculation
TOTAL_CORES=$(nproc)
TOTAL_MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
HALF_CORES=$(echo "$TOTAL_CORES / 2" | bc)
HALF_MEM_MB=$(echo "$TOTAL_MEM_KB / 1024 / 2" | bc)

# Ensure at least 1 core for half-host
if [ "$HALF_CORES" -lt 1 ]; then HALF_CORES=1; fi

# 3. Mode Selection
MODE=${1:-"dual"}

case $MODE in
    "dual")
        echo "[MODE] Dual: 2 instances (1 CPU, 8G RAM each)"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        export G2_CPU="1.0"
        export G2_MEM="8G"
        COMPOSE_ARGS="--profile dual up -d"
        ;;
    "single")
        echo "[MODE] Single: 1 instance (1 CPU, 8G RAM)"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        COMPOSE_ARGS="up -d ubuntu-container"
        ;;
    "power")
        echo "[MODE] Power: 1 instance (2 CPU, 16G RAM)"
        export G1_CPU="2.0"
        export G1_MEM="16G"
        COMPOSE_ARGS="up -d ubuntu-container"
        ;;
    "half")
        echo "[MODE] Half-Host: 1 instance ($HALF_CORES CPU, ${HALF_MEM_MB}M RAM)"
        export G1_CPU="$HALF_CORES.0"
        export G1_MEM="${HALF_MEM_MB}M"
        COMPOSE_ARGS="up -d ubuntu-container"
        ;;
    *)
        echo "Usage: ./start.sh [dual|single|power|half]"
        exit 1
        ;;
esac

# 4. Execution
docker compose $COMPOSE_ARGS
