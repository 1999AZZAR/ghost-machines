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
HALF_CORES=$((TOTAL_CORES / 2))
HALF_MEM_MB=$((TOTAL_MEM_KB / 1024 / 2))

if [ "$HALF_CORES" -lt 1 ]; then HALF_CORES=1; fi

# 3. Engine & Mode Selection
if [ -z "$1" ] || [[ "$1" == -* ]]; then
    echo "------------------------------------------------"
    echo " GHOST MACHINES: ENGINE SELECTION"
    echo "------------------------------------------------"
    echo "1) Ubuntu (Standard)"
    echo "2) Debian (Slim/Lightweight)"
    read -p "Select Engine [1-2]: " ENG_CHOICE
    case $ENG_CHOICE in
        1) export GHOST_DOCKERFILE="Dockerfile"; export GHOST_IMAGE="ubuntu-template:latest" ;;
        2) export GHOST_DOCKERFILE="Dockerfile.debian"; export GHOST_IMAGE="debian-template:latest" ;;
        *) echo "[ERROR] Invalid selection."; exit 1 ;;
    esac

    echo "------------------------------------------------"
    echo " GHOST MACHINES: DEPLOYMENT SELECTION"
    echo "------------------------------------------------"
    echo "1) Dual   - 2 instances"
    echo "2) Single - 1 instance"
    echo "3) Power  - 1 instance (High Resource)"
    echo "4) Half   - 1 instance (50% Host)"
    read -p "Select mode [1-4]: " CHOICE
    case $CHOICE in
        1) MODE="dual" ;;
        2) MODE="single" ;;
        3) MODE="power" ;;
        4) MODE="half" ;;
        *) echo "[ERROR] Invalid selection."; exit 1 ;;
    esac
else
    # Detect engine from first char if provided as argument (e.g., d-dual or u-single)
    # Or just default to Ubuntu for simplicity in arguments for now
    export GHOST_DOCKERFILE="Dockerfile"
    export GHOST_IMAGE="ubuntu-template:latest"
    MODE=$1
    shift
fi

# 4. Profile Management
REMOTE_PROFILE=""
if [ ! -z "$TUNNEL_TOKEN" ]; then
    echo "[INFO] Cloudflare Tunnel Token detected. Enabling remote access profile."
    REMOTE_PROFILE="--profile remote"
fi

case $MODE in
    "dual")
        echo "[MODE] Dual Deployment"
        export G1_NAME="ghost-machine1"
        export G2_NAME="ghost-machine2"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        export G2_CPU="1.0"
        export G2_MEM="8G"
        COMPOSE_ARGS="$REMOTE_PROFILE --profile dual up -d"
        ;;
    "single")
        echo "[MODE] Single Instance"
        export G1_NAME="ghost-machine-single"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        COMPOSE_ARGS="$REMOTE_PROFILE up -d ghost1"
        ;;
    "power")
        echo "[MODE] Power Instance"
        export G1_NAME="ghost-machine-power"
        export G1_CPU="2.0"
        export G1_MEM="16G"
        COMPOSE_ARGS="$REMOTE_PROFILE up -d ghost1"
        ;;
    "half")
        echo "[MODE] Half-Host Instance ($HALF_CORES CPU, ${HALF_MEM_MB}M RAM)"
        export G1_NAME="ghost-machine-half"
        export G1_CPU="$HALF_CORES.0"
        export G1_MEM="${HALF_MEM_MB}M"
        COMPOSE_ARGS="$REMOTE_PROFILE up -d ghost1"
        ;;
esac

docker compose $COMPOSE_ARGS "$@"
