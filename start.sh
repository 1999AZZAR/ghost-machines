#!/bin/bash

# Ghost Machines: Intelligent Entry Point
# Supports interactive mode, CLI arguments, dynamic UID/GID synchronization,
# automated hardware detection, and security hardening.

set -e

# 1. Host Identity & Security Sync
export HOST_UID="${HOST_UID:-$(id -u)}"
export HOST_GID="${HOST_GID:-$(id -g)}"
export GHOST_USER="${GHOST_USER:-developer}"

# 1.1 Secure .env Permissions
if [ -f ".env" ]; then
    ENV_PERM=$(stat -c "%a" .env 2>/dev/null || stat -f "%Lp" .env 2>/dev/null || echo "")
    if [ -n "$ENV_PERM" ] && [ "$ENV_PERM" != "600" ]; then
        chmod 600 .env 2>/dev/null || true
        echo "[SECURITY] Hardened .env permissions to 600."
    fi
fi

# 1.2 SSH Public Key Detection
if [ -z "$SSH_AUTH_KEY_PATH" ]; then
    for KEY_FILE in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_rsa.pub" "$HOME/.ssh/authorized_keys"; do
        if [ -f "$KEY_FILE" ]; then
            export SSH_AUTH_KEY_PATH="$KEY_FILE"
            echo "[SECURITY] Detected host SSH public key: $KEY_FILE"
            break
        fi
    done
fi
if [ -z "$SSH_AUTH_KEY_PATH" ]; then
    export SSH_AUTH_KEY_PATH="/dev/null"
fi

# 2. LXCFS Detection
export LXCFS_BASE="/var/lib/lxcfs/proc"
if [ -d "$LXCFS_BASE" ]; then
    echo "[INFO] LXCFS detected. Enabling hardware reporting mounts."
    export LXCFS_CPUINFO="$LXCFS_BASE/cpuinfo"
    export LXCFS_MEMINFO="$LXCFS_BASE/meminfo"
    export LXCFS_STAT="$LXCFS_BASE/stat"
    export LXCFS_SWAPS="$LXCFS_BASE/swaps"
    export LXCFS_UPTIME="$LXCFS_BASE/uptime"
fi

# 3. Host Resource Calculation
TOTAL_CORES=$(nproc)
TOTAL_MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo 2>/dev/null || echo "16777216")
HALF_CORES=$((TOTAL_CORES / 2))
HALF_MEM_MB=$((TOTAL_MEM_KB / 1024 / 2))

if [ "$HALF_CORES" -lt 1 ]; then HALF_CORES=1; fi

# 4. Engine & Mode Selection
if [ -z "$1" ] || [[ "$1" == -* ]]; then
    echo "------------------------------------------------"
    echo " GHOST MACHINES: ENGINE SELECTION"
    echo "------------------------------------------------"
    echo "1) Ubuntu (Standard)"
    echo "2) Debian (Slim/Lightweight)"
    echo "3) Alpine (Ultra-Lightweight)"
    echo "4) Arch   (Rolling Release)"
    read -p "Select Engine [1-4]: " ENG_CHOICE
    case $ENG_CHOICE in
        1) export GHOST_DOCKERFILE="Dockerfile"; export GHOST_IMAGE="ubuntu-template:latest" ;;
        2) export GHOST_DOCKERFILE="Dockerfile.debian"; export GHOST_IMAGE="debian-template:latest" ;;
        3) export GHOST_DOCKERFILE="Dockerfile.alpine"; export GHOST_IMAGE="alpine-template:latest" ;;
        4) export GHOST_DOCKERFILE="Dockerfile.arch"; export GHOST_IMAGE="arch-template:latest" ;;
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
    # Default to Ubuntu for CLI arguments
    export GHOST_DOCKERFILE="Dockerfile"
    export GHOST_IMAGE="ubuntu-template:latest"
    MODE=$1
    shift
fi

# 5. Profile Management & Pre-Flight Validation
REMOTE_PROFILE=""
if [ -n "$TUNNEL_TOKEN" ]; then
    if [ "$TUNNEL_TOKEN" = "your_cloudflare_tunnel_token" ] || [ ${#TUNNEL_TOKEN} -lt 10 ]; then
        echo "[WARNING] TUNNEL_TOKEN appears to be a placeholder or invalid. Skipping Cloudflare remote tunnel."
    else
        echo "[INFO] Valid Cloudflare Tunnel Token detected. Enabling remote access profile."
        REMOTE_PROFILE="--profile remote"
    fi
fi

case $MODE in
    "dual")
        echo "[MODE] Dual Deployment (UID: $HOST_UID, GID: $HOST_GID)"
        export G1_NAME="ghost-machine1"
        export G2_NAME="ghost-machine2"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        export G2_CPU="1.0"
        export G2_MEM="8G"
        COMPOSE_ARGS="$REMOTE_PROFILE --profile dual up -d"
        ;;
    "single")
        echo "[MODE] Single Instance (UID: $HOST_UID, GID: $HOST_GID)"
        export G1_NAME="ghost-machine-single"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        COMPOSE_ARGS="$REMOTE_PROFILE up -d ghost1"
        ;;
    "power")
        echo "[MODE] Power Instance (UID: $HOST_UID, GID: $HOST_GID)"
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
    *)
        echo "[ERROR] Unknown mode: $MODE"
        exit 1
        ;;
esac

docker compose $COMPOSE_ARGS "$@"
