#!/bin/bash

# Ghost Machines: Intelligent Entry Point
# Supports interactive mode, CLI flags, dynamic UID/GID synchronization,
# automated hardware detection, multi-engine routing, and security hardening.

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

# 1.3 Host Antigravity CLI Binary Detection
if [ -z "$HOST_AGY_BIN" ]; then
    for AGY_CANDIDATE in "$HOME/.local/bin/agy" "/usr/local/bin/agy" "/usr/bin/agy"; do
        if [ -f "$AGY_CANDIDATE" ]; then
            export HOST_AGY_BIN="$AGY_CANDIDATE"
            break
        fi
    done
fi
if [ -z "$HOST_AGY_BIN" ]; then
    export HOST_AGY_BIN="/dev/null"
fi

# 2. LXCFS Detection
SKIP_LXCFS=false
export LXCFS_BASE="/var/lib/lxcfs/proc"
if [ "$SKIP_LXCFS" = false ] && [ -d "$LXCFS_BASE" ]; then
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

# 4. CLI Argument Parsing
ENGINE_ARG=""
ENGINE_KEY=""
MODE_ARG=""
PORT_ARG=""
TUNNEL_ARG=""
BUILD_FLAG=""
USER_IMAGE=""
PREBUILT=false
PULL_IMAGE=false
UPDATE_HARNESS=false
LIFECYCLE_ACTION=""
EXTRA_COMPOSE_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -e|--engine)
            ENGINE_ARG="$2"
            shift 2
            ;;
        -m|--mode)
            MODE_ARG="$2"
            shift 2
            ;;
        -p|--port)
            PORT_ARG="$2"
            shift 2
            ;;
        -t|--tunnel)
            TUNNEL_ARG="$2"
            shift 2
            ;;
        -b|--build|-r|--rebuild)
            BUILD_FLAG="--build"
            shift
            ;;
        --image)
            USER_IMAGE="${2:-}"
            [ -n "$USER_IMAGE" ] || { echo "[ERROR] --image requires a reference"; exit 1; }
            shift 2
            ;;
        --prebuilt)
            PREBUILT=true
            if [ $# -ge 2 ]; then
                case "${2,,}" in
                    ubuntu|debian|alpine|arch) ENGINE_ARG="$2"; shift ;;
                esac
            fi
            shift
            ;;
        --pull)
            PULL_IMAGE=true
            shift
            ;;
        -u|--update-harness)
            UPDATE_HARNESS=true
            shift
            ;;
        --no-lxcfs)
            SKIP_LXCFS=true
            unset LXCFS_CPUINFO LXCFS_MEMINFO LXCFS_STAT LXCFS_SWAPS LXCFS_UPTIME
            shift
            ;;
        -h|--help)
            echo "Ghost Machines — Development Environment Orchestrator"
            echo ""
            echo "Usage: ./start.sh [options] [-- docker compose args...]"
            echo "       ./start.sh <stop|status|logs|restart>"
            echo ""
            echo "Lifecycle:"
            echo "  stop                                      Stop and remove containers (work in mounts/ is kept)"
            echo "  status                                    Show container state, SSH ports and image in use"
            echo "  logs                                      Follow container logs"
            echo "  restart                                   Restart existing containers"
            echo ""
            echo "Options:"
            echo "  -e, --engine <ubuntu|debian|alpine|arch>  Select OS base engine"
            echo "  -m, --mode <dual|single|power|half>       Select deployment resource mode"
            echo "  -p, --port <port>                         Set base SSH port (default: 2223)"
            echo "  -t, --tunnel <token>                      Set Cloudflare Tunnel token"
            echo "  -b, --build, --rebuild                    Build the image locally before starting"
            echo "      --prebuilt [engine]                   Use the GHCR prebuilt image (no local build)"
            echo "      --image <ref>                         Use an explicit image reference (pulled if missing)"
            echo "      --pull                                Force-pull the image before starting"
            echo "  -u, --update-harness                      Refresh opencode/agy/rtk to latest after start"
            echo "      --no-lxcfs                            Disable LXCFS volume mounts"
            echo "  -h, --help                                Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./start.sh --prebuilt ubuntu -m single    # GHCR image, no build"
            echo "  ./start.sh -e debian -m single --build    # build from Dockerfile"
            echo "  ./start.sh -e arch -m power -p 3333"
            echo "  ./start.sh dual --update-harness"
            echo "  ./start.sh status"
            exit 0
            ;;
        stop|down|status|logs|restart)
            LIFECYCLE_ACTION="$1"
            shift
            [ $# -gt 0 ] && EXTRA_COMPOSE_ARGS=("$@")
            set --
            ;;
        dual|single|power|half)
            MODE_ARG="$1"
            shift
            ;;
        *)
            EXTRA_COMPOSE_ARGS+=("$1")
            shift
            ;;
    esac
done

# 4.1 Handle Port Overrides
if [ -n "$PORT_ARG" ]; then
    export G1_PORT="$PORT_ARG"
    export G2_PORT="$((PORT_ARG + 1))"
fi

# 4.2 Handle Tunnel Token Overrides
if [ -n "$TUNNEL_ARG" ]; then
    export TUNNEL_TOKEN="$TUNNEL_ARG"
fi

# 4.2.1 Lifecycle verbs (status / stop / logs / restart) — no engine or mode needed
if [ -n "$LIFECYCLE_ACTION" ]; then
    COMPOSE_LIFECYCLE=(docker compose --profile dual --profile remote)
    case "$LIFECYCLE_ACTION" in
        stop|down)
            echo "[STOP] Removing Ghost containers (images, network and mounts/ are kept)..."
            "${COMPOSE_LIFECYCLE[@]}" down --remove-orphans
            echo "[STOP] Done. Work in mounts/ is untouched; use ./start.sh to bring it back."
            ;;
        status)
            "${COMPOSE_LIFECYCLE[@]}" ps
            echo ""
            echo "SSH endpoints:"
            FOUND_CONTAINER=false
            for CONTAINER in $(docker ps --filter "name=ghost" --format '{{.Names}}'); do
                FOUND_CONTAINER=true
                MAPPED_PORT=$(docker port "$CONTAINER" 22/tcp 2>/dev/null | head -n 1 | sed 's/.*://')
                printf '  %-24s ssh -p %s developer@localhost\n' "$CONTAINER" "${MAPPED_PORT:-?}"
            done
            [ "$FOUND_CONTAINER" = true ] || echo "  (nothing running — start with ./start.sh or ./start.sh --prebuilt ubuntu -m single)"
            ;;
        logs)
            "${COMPOSE_LIFECYCLE[@]}" logs --tail 200 -f
            ;;
        restart)
            echo "[RESTART] Restarting existing Ghost containers..."
            "${COMPOSE_LIFECYCLE[@]}" restart
            ;;
    esac
    exit 0
fi

# 4.3 Handle Engine Selection (respect prebuilt GHOST_IMAGE if set externally)
GHCR_PREFIX="ghcr.io/1999azzar/ghost-machine"

if [ -n "$ENGINE_ARG" ]; then
    case "${ENGINE_ARG,,}" in
        ubuntu) ENGINE_KEY="ubuntu"; export GHOST_DOCKERFILE="Dockerfile"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="ubuntu-template:latest" ;;
        debian) ENGINE_KEY="debian"; export GHOST_DOCKERFILE="Dockerfile.debian"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="debian-template:latest" ;;
        alpine) ENGINE_KEY="alpine"; export GHOST_DOCKERFILE="Dockerfile.alpine"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="alpine-template:latest" ;;
        arch)   ENGINE_KEY="arch"; export GHOST_DOCKERFILE="Dockerfile.arch"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="arch-template:latest" ;;
        *) echo "[ERROR] Unknown engine: $ENGINE_ARG (supported: ubuntu, debian, alpine, arch)"; exit 1 ;;
    esac
elif [ -z "$MODE_ARG" ]; then
    echo "------------------------------------------------"
    echo " GHOST MACHINES: ENGINE SELECTION"
    echo "------------------------------------------------"
    echo "1) Ubuntu (Standard)"
    echo "2) Debian (Slim/Lightweight)"
    echo "3) Alpine (Ultra-Lightweight)"
    echo "4) Arch   (Rolling Release)"
    read -r -p "Select Engine [1-4]: " ENG_CHOICE
    case $ENG_CHOICE in
        1) ENGINE_KEY="ubuntu"; export GHOST_DOCKERFILE="Dockerfile"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="ubuntu-template:latest" ;;
        2) ENGINE_KEY="debian"; export GHOST_DOCKERFILE="Dockerfile.debian"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="debian-template:latest" ;;
        3) ENGINE_KEY="alpine"; export GHOST_DOCKERFILE="Dockerfile.alpine"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="alpine-template:latest" ;;
        4) ENGINE_KEY="arch"; export GHOST_DOCKERFILE="Dockerfile.arch"; [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="arch-template:latest" ;;
        *) echo "[ERROR] Invalid selection."; exit 1 ;;
    esac
else
    # Default to Ubuntu when mode is given positionally without engine
    ENGINE_KEY="ubuntu"
    export GHOST_DOCKERFILE="Dockerfile"
    [ -n "${GHOST_IMAGE:-}" ] || export GHOST_IMAGE="ubuntu-template:latest"
fi

# 4.3.1 Resolve image source: --image > --prebuilt > GHOST_IMAGE from the environment
if [ -n "$USER_IMAGE" ]; then
    export GHOST_IMAGE="$USER_IMAGE"
elif [ "$PREBUILT" = true ]; then
    case "$ENGINE_KEY" in
        ubuntu) export GHOST_DOCKERFILE="Dockerfile";     export GHOST_IMAGE="${GHCR_PREFIX}-ubuntu:latest" ;;
        debian) export GHOST_DOCKERFILE="Dockerfile.debian"; export GHOST_IMAGE="${GHCR_PREFIX}-debian:latest" ;;
        alpine) export GHOST_DOCKERFILE="Dockerfile.alpine"; export GHOST_IMAGE="${GHCR_PREFIX}-alpine:latest" ;;
        arch)   export GHOST_DOCKERFILE="Dockerfile.arch";   export GHOST_IMAGE="${GHCR_PREFIX}-arch:latest" ;;
    esac
fi

# A reference containing "/" comes from a registry; anything else is a local build tag.
IS_PREBUILT=false
case "$GHOST_IMAGE" in
    */*) IS_PREBUILT=true ;;
esac

# 4.4 Handle Mode Selection
if [ -n "$MODE_ARG" ]; then
    MODE="${MODE_ARG,,}"
else
    echo "------------------------------------------------"
    echo " GHOST MACHINES: DEPLOYMENT SELECTION"
    echo "------------------------------------------------"
    echo "1) Dual   - 2 instances"
    echo "2) Single - 1 instance"
    echo "3) Power  - 1 instance (High Resource)"
    echo "4) Half   - 1 instance (50% Host)"
    read -r -p "Select mode [1-4]: " CHOICE
    case $CHOICE in
        1) MODE="dual" ;;
        2) MODE="single" ;;
        3) MODE="power" ;;
        4) MODE="half" ;;
        *) echo "[ERROR] Invalid selection."; exit 1 ;;
    esac
fi

# 5. Profile Management & Pre-Flight Validation
REMOTE_PROFILE_ARGS=()
if [ -n "$TUNNEL_TOKEN" ]; then
    if [ "$TUNNEL_TOKEN" = "your_cloudflare_tunnel_token" ] || [ ${#TUNNEL_TOKEN} -lt 10 ]; then
        echo "[WARNING] TUNNEL_TOKEN appears to be a placeholder or invalid. Skipping Cloudflare remote tunnel."
    else
        echo "[INFO] Valid Cloudflare Tunnel Token detected. Enabling remote access profile."
        REMOTE_PROFILE_ARGS=(--profile remote)
    fi
fi

BUILD_OPTS=()
if [ -n "$BUILD_FLAG" ]; then
    if [ "$IS_PREBUILT" = true ]; then
        echo "[INFO] $GHOST_IMAGE is a registry image; skipping local build (drop --build to silence)."
    else
        BUILD_OPTS=("$BUILD_FLAG")
    fi
fi

if [ "$IS_PREBUILT" = true ]; then
    if ! docker image inspect "$GHOST_IMAGE" >/dev/null 2>&1; then
        echo "[PULL] $GHOST_IMAGE not present locally — pulling it now..."
        docker pull "$GHOST_IMAGE"
    elif [ "$PULL_IMAGE" = true ]; then
        echo "[PULL] Refreshing $GHOST_IMAGE from the registry..."
        docker pull "$GHOST_IMAGE"
    fi
fi

if [ "$IS_PREBUILT" = true ]; then
    echo "[IMAGE] $GHOST_IMAGE (GHCR prebuilt, no local build)"
else
    echo "[IMAGE] $GHOST_IMAGE (local build from $GHOST_DOCKERFILE)"
fi

case $MODE in
    "dual")
        echo "[MODE] Dual Deployment (Image: $GHOST_IMAGE, UID: $HOST_UID, GID: $HOST_GID, Port: ${G1_PORT:-2223})"
        export G1_NAME="ghost-machine1"
        export G2_NAME="ghost-machine2"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        export G2_CPU="1.0"
        export G2_MEM="8G"
        COMPOSE_FINAL_ARGS=("${REMOTE_PROFILE_ARGS[@]}" --profile dual up -d "${BUILD_OPTS[@]}")
        ;;
    "single")
        echo "[MODE] Single Instance (Image: $GHOST_IMAGE, UID: $HOST_UID, GID: $HOST_GID, Port: ${G1_PORT:-2223})"
        export G1_NAME="ghost-machine-single"
        export G1_CPU="1.0"
        export G1_MEM="8G"
        COMPOSE_FINAL_ARGS=("${REMOTE_PROFILE_ARGS[@]}" up -d "${BUILD_OPTS[@]}" ghost1)
        ;;
    "power")
        echo "[MODE] Power Instance (Image: $GHOST_IMAGE, UID: $HOST_UID, GID: $HOST_GID, Port: ${G1_PORT:-2223})"
        export G1_NAME="ghost-machine-power"
        export G1_CPU="2.0"
        export G1_MEM="16G"
        COMPOSE_FINAL_ARGS=("${REMOTE_PROFILE_ARGS[@]}" up -d "${BUILD_OPTS[@]}" ghost1)
        ;;
    "half")
        echo "[MODE] Half-Host Instance ($HALF_CORES CPU, ${HALF_MEM_MB}M RAM)"
        export G1_NAME="ghost-machine-half"
        export G1_CPU="$HALF_CORES.0"
        export G1_MEM="${HALF_MEM_MB}M"
        COMPOSE_FINAL_ARGS=("${REMOTE_PROFILE_ARGS[@]}" up -d "${BUILD_OPTS[@]}" ghost1)
        ;;
    *)
        echo "[ERROR] Unknown mode: $MODE (supported: dual, single, power, half)"
        exit 1
        ;;
esac

docker compose "${COMPOSE_FINAL_ARGS[@]}" "${EXTRA_COMPOSE_ARGS[@]}"

# 6. Optional: refresh the built-in harness binaries (opencode/agy/rtk) to latest
if [ "$UPDATE_HARNESS" = true ]; then
    for CONTAINER in "${G1_NAME:-}" "${G2_NAME:-}"; do
        [ -n "$CONTAINER" ] || continue
        if [ "$(docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null || echo false)" != "true" ]; then
            continue
        fi
        echo "[UPDATE] Refreshing built-in harnesses in $CONTAINER ..."
        docker exec -u root "$CONTAINER" /usr/local/bin/harness-update \
            || echo "[WARNING] Harness refresh failed in $CONTAINER"
    done
fi
