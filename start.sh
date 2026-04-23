#!/bin/bash

# Ghost Machines: Intelligent Entry Point
# Supports interactive mode, CLI arguments, and automated hardware detection.

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

if [ "$HALF_CORES" -lt 1 ]; then HALF_CORES=1; fi

# 3. Mode Selection
if [ -z "$1" ]; then
    echo "------------------------------------------------"
    echo " GHOST MACHINES: DEPLOYMENT SELECTION"
    echo "------------------------------------------------"
    echo "1) Dual   - 2 instances (ghost-machine1, ghost-machine2)"
    echo "2) Single - 1 instance  (ghost-machine-single)"
    echo "3) Power  - 1 instance  (ghost-machine-power)"
    echo "4) Half   - 1 instance  (ghost-machine-half)"
    echo "------------------------------------------------"
    read -p "Select mode [1-4]: " CHOICE
    case $CHOICE in
        1) MODE="dual" ;;
        2) MODE="single" ;;
        3) MODE="power" ;;
        4) MODE="half" ;;
        *) echo "[ERROR] Invalid selection."; exit 1 ;;
    esac
else
    MODE=$1
fi

case $MODE in
    "dual")
        echo "[MODE] Dual: 2 instances"
        export G1_NAME="ghost-machine1"
        export G2_NAME="ghost-machine2"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        export G2_CPU="1.0"
        export G2_MEM="8G"
        COMPOSE_ARGS="--profile dual up -d"
        ;;
    "single")
        echo "[MODE] Single: ghost-machine-single"
        export G1_NAME="ghost-machine-single"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        COMPOSE_ARGS="up -d ghost1"
        ;;
    "power")
        echo "[MODE] Power: ghost-machine-power"
        export G1_NAME="ghost-machine-power"
        export G1_CPU="2.0"
        export G1_MEM="16G"
        COMPOSE_ARGS="up -d ghost1"
        ;;
    "half")
        echo "[MODE] Half-Host: ghost-machine-half"
        export G1_NAME="ghost-machine-half"
        export G1_CPU="$HALF_CORES.0"
        export G1_MEM="${HALF_MEM_MB}M"
        COMPOSE_ARGS="up -d ghost1"
        ;;
    *)
        echo "Usage: ./start.sh [dual|single|power|half]"
        exit 1
        ;;
esac

# 4. Execution
docker compose $COMPOSE_ARGS
