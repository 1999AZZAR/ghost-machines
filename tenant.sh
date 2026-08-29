#!/bin/bash

# Ghost Machines: Multi-Tenant Workspace-as-a-Service Orchestrator
# Dynamically provisions, scales, monitors, snapshots, and manages multi-tenant AI developer sandboxes.

set -e

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export GHOST_BASE_DIR="$BASE_DIR"
CONFIG_DIR="$BASE_DIR/config"
TENANTS_FILE="$CONFIG_DIR/tenants.json"
MOUNTS_BASE="$BASE_DIR/mounts/tenants"
TEMPLATES_DIR="$BASE_DIR/templates"
TEMPLATE_COMPOSE="$TEMPLATES_DIR/docker-compose.tenant.yml"

mkdir -p "$CONFIG_DIR" "$MOUNTS_BASE" "$TEMPLATES_DIR"

if [ ! -f "$TENANTS_FILE" ]; then
    echo '{"version": "1.0", "tenants": {}}' > "$TENANTS_FILE"
fi

show_help() {
    cat << 'HELP'
Ghost Machines — Multi-Tenant Workstation Orchestrator

Usage: ./tenant.sh <command> [options]

Commands:
  add <tenant_id>       Provision a new tenant workspace
  list                  List all active and configured tenants
  stats [tenant_id]     Show live CPU/RAM stats for tenant containers
  start <tenant_id>     Start a stopped tenant workspace
  stop <tenant_id>      Stop an active tenant workspace
  restart <tenant_id>   Restart a tenant workspace
  exec <tenant_id> <cmd> Execute a command inside a tenant container
  snapshot <tenant_id>  Create point-in-time backup for a tenant
  restore <tenant_id>   Restore a tenant from a snapshot archive
  delete <tenant_id>    Tear down and remove a tenant workspace
  help, -h, --help      Show this help message

Options for 'add':
  -e, --engine <name>   OS engine (debian, ubuntu, alpine, arch) [default: debian]
  -p, --port <port>     Host SSH port (default: auto-allocated >= 2225)
  -c, --cpu <cpus>      CPU quota [default: 2.0]
  -m, --mem <memory>    Memory limit [default: 4G]
  -u, --user <name>     Workspace user [default: developer]
  -k, --pubkey <path>   Host SSH public key path for key-based login
  -b, --build           Force rebuild of base image
  -y, --yes             Skip interactive prompts

Examples:
  ./tenant.sh add alice --engine debian --cpu 2.0 --mem 4G --port 2225
  ./tenant.sh add bob --engine arch --cpu 4.0 --mem 8G
  ./tenant.sh list
  ./tenant.sh snapshot alice
  ./tenant.sh delete bob --archive
HELP
}

# Ensure global ghost_sandbox docker network exists
ensure_network() {
    if ! docker network inspect ghost_sandbox >/dev/null 2>&1; then
        docker network create ghost_sandbox >/dev/null
    fi
}

# Detect LXCFS mounts
detect_lxcfs() {
    if [ -d "/var/lib/lxcfs/proc" ]; then
        export LXCFS_CPUINFO="/var/lib/lxcfs/proc/cpuinfo"
        export LXCFS_MEMINFO="/var/lib/lxcfs/proc/meminfo"
        export LXCFS_STAT="/var/lib/lxcfs/proc/stat"
        export LXCFS_SWAPS="/var/lib/lxcfs/proc/swaps"
        export LXCFS_UPTIME="/var/lib/lxcfs/proc/uptime"
    else
        export LXCFS_CPUINFO="/dev/null"
        export LXCFS_MEMINFO="/dev/null"
        export LXCFS_STAT="/dev/null"
        export LXCFS_SWAPS="/dev/null"
        export LXCFS_UPTIME="/dev/null"
    fi
}

# Auto-allocate next free SSH port starting from 2225
find_next_port() {
    local candidate=2225
    while true; do
        # Check if port is already recorded in tenants.json
        local in_json
        in_json=$(jq -r --arg p "$candidate" '.tenants[] | select(.port == ($p | tonumber)) | .id' "$TENANTS_FILE" 2>/dev/null || true)
        
        # Check if port is listening on host
        local in_use=false
        if [ -n "$in_json" ]; then
            in_use=true
        elif command -v ss >/dev/null 2>&1; then
            if ss -tulpn 2>/dev/null | grep -q ":$candidate "; then
                in_use=true
            fi
        elif command -v netstat >/dev/null 2>&1; then
            if netstat -tulpn 2>/dev/null | grep -q ":$candidate "; then
                in_use=true
            fi
        fi

        if [ "$in_use" = false ]; then
            echo "$candidate"
            return 0
        fi
        candidate=$((candidate + 1))
    done
}

# Helper to read tenant record
get_tenant_field() {
    local tid="$1"
    local field="$2"
    jq -r --arg tid "$tid" --arg f "$field" '.tenants[$tid][$f] // empty' "$TENANTS_FILE"
}

# Provision a new tenant
cmd_add() {
    local TENANT_ID="$1"
    shift || true

    if [ -z "$TENANT_ID" ]; then
        echo "[ERROR] Tenant ID is required. Example: ./tenant.sh add alice"
        exit 1
    fi

    # Validate Tenant ID format (alphanumeric and hyphens only)
    if [[ ! "$TENANT_ID" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "[ERROR] Invalid Tenant ID. Only alphanumeric characters, dashes, and underscores allowed."
        exit 1
    fi

    # Check if tenant already exists
    local exists
    exists=$(jq -r --arg tid "$TENANT_ID" '.tenants[$tid].id // empty' "$TENANTS_FILE")
    if [ -n "$exists" ]; then
        echo "[ERROR] Tenant '$TENANT_ID' already exists in registry. Use './tenant.sh delete $TENANT_ID' first."
        exit 1
    fi

    local ENGINE="debian"
    local PORT=""
    local CPU="2.0"
    local MEM="4G"
    local USER_NAME="developer"
    local PUBKEY_PATH=""
    local DO_BUILD=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--engine)
                ENGINE="$2"
                shift 2
                ;;
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -c|--cpu)
                CPU="$2"
                shift 2
                ;;
            -m|--mem)
                MEM="$2"
                shift 2
                ;;
            -u|--user)
                USER_NAME="$2"
                shift 2
                ;;
            -k|--pubkey)
                PUBKEY_PATH="$2"
                shift 2
                ;;
            -b|--build)
                DO_BUILD=true
                shift
                ;;
            *)
                echo "[ERROR] Unknown option: $1"
                exit 1
                ;;
        esac
    done

    # Select Dockerfile and Image tag based on engine
    local DOCKERFILE="Dockerfile.debian"
    local IMAGE_TAG="debian-template:latest"
    case "$ENGINE" in
        debian)
            DOCKERFILE="Dockerfile.debian"
            IMAGE_TAG="debian-template:latest"
            ;;
        ubuntu)
            DOCKERFILE="Dockerfile"
            IMAGE_TAG="ubuntu-template:latest"
            ;;
        alpine)
            DOCKERFILE="Dockerfile.alpine"
            IMAGE_TAG="alpine-template:latest"
            ;;
        arch)
            DOCKERFILE="Dockerfile.arch"
            IMAGE_TAG="arch-template:latest"
            ;;
        *)
            echo "[ERROR] Unsupported engine '$ENGINE'. Choose debian, ubuntu, alpine, or arch."
            exit 1
            ;;
    esac

    # Auto-allocate port if not provided
    if [ -z "$PORT" ]; then
        PORT=$(find_next_port)
    fi

    # Host UID/GID Sync
    local HOST_UID
    local HOST_GID
    HOST_UID=$(id -u)
    HOST_GID=$(id -g)

    # Handle SSH Public Key
    if [ -z "$PUBKEY_PATH" ]; then
        if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
            PUBKEY_PATH="$HOME/.ssh/id_ed25519.pub"
        elif [ -f "$HOME/.ssh/id_rsa.pub" ]; then
            PUBKEY_PATH="$HOME/.ssh/id_rsa.pub"
        else
            PUBKEY_PATH="/dev/null"
        fi
    fi

    local CONTAINER_NAME="ghost-tenant-$TENANT_ID"
    local PROJECT_NAME="ghost-tenant-$TENANT_ID"
    local TENANT_MOUNT="$MOUNTS_BASE/$TENANT_ID"

    echo "=================================================="
    echo " PROVISIONING GHOST TENANT: $TENANT_ID"
    echo "=================================================="
    echo "Engine:         $ENGINE ($IMAGE_TAG)"
    echo "Container Name: $CONTAINER_NAME"
    echo "SSH Port:       $PORT"
    echo "CPU Limit:      $CPU cores"
    echo "RAM Limit:      $MEM"
    echo "Workspace User: $USER_NAME"
    echo "Storage Path:   $TENANT_MOUNT"
    echo "=================================================="

    ensure_network
    detect_lxcfs

    # Create isolated workspace volume directory
    mkdir -p "$TENANT_MOUNT"
    touch "$TENANT_MOUNT/.gitkeep"

    # Export environment variables for Compose
    export TENANT_DOCKERFILE="$DOCKERFILE"
    export TENANT_IMAGE="$IMAGE_TAG"
    export TENANT_CONTAINER_NAME="$CONTAINER_NAME"
    export TENANT_USER="$USER_NAME"
    export TENANT_PORT="$PORT"
    export TENANT_CPU="$CPU"
    export TENANT_MEM="$MEM"
    export TENANT_MOUNT_PATH="$TENANT_MOUNT"
    export TENANT_AUTH_KEY_PATH="$PUBKEY_PATH"
    export HOST_UID="$HOST_UID"
    export HOST_GID="$HOST_GID"
    export HOST_AGY_BIN="${HOST_AGY_BIN:-/dev/null}"
    export MCP_ECOSYSTEM_LOCAL_PATH="${MCP_ECOSYSTEM_LOCAL_PATH:-/dev/null}"

    local COMPOSE_CMD=(docker compose -p "$PROJECT_NAME" -f "$TEMPLATE_COMPOSE")

    if [ "$DO_BUILD" = true ]; then
        echo "[INFO] Building image $IMAGE_TAG for tenant..."
        "${COMPOSE_CMD[@]}" build
    fi

    echo "[INFO] Launching tenant container $CONTAINER_NAME..."
    "${COMPOSE_CMD[@]}" up -d

    # Update Registry in config/tenants.json
    local NOW
    NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local TMP_JSON
    TMP_JSON=$(mktemp)
    jq --arg tid "$TENANT_ID" \
       --arg engine "$ENGINE" \
       --arg img "$IMAGE_TAG" \
       --arg cname "$CONTAINER_NAME" \
       --arg pname "$PROJECT_NAME" \
       --argjson port "$PORT" \
       --arg cpu "$CPU" \
       --arg mem "$MEM" \
       --arg user "$USER_NAME" \
       --arg mount "$TENANT_MOUNT" \
       --arg created "$NOW" \
       '.tenants[$tid] = {
           id: $tid,
           engine: $engine,
           image: $img,
           container_name: $cname,
           project_name: $pname,
           port: $port,
           cpu_limit: $cpu,
           mem_limit: $mem,
           username: $user,
           mount_path: $mount,
           created_at: $created,
           status: "running"
       }' "$TENANTS_FILE" > "$TMP_JSON" && mv "$TMP_JSON" "$TENANTS_FILE"

    echo ""
    echo "=================================================="
    echo " [SUCCESS] TENANT $TENANT_ID PROVISIONED!"
    echo "=================================================="
    echo "Connect via SSH:"
    echo "  ssh -p $PORT $USER_NAME@localhost"
    echo "  Password: ghost (sudo: ghost)"
    echo "=================================================="
}

# List all tenants
cmd_list() {
    local COUNT
    COUNT=$(jq '.tenants | length' "$TENANTS_FILE" 2>/dev/null || echo "0")
    if [ "$COUNT" -eq 0 ]; then
        echo "[INFO] No tenants currently provisioned. Add one using: ./tenant.sh add <name>"
        return 0
    fi

    echo "========================================================================================================="
    printf "%-12s %-8s %-6s %-10s %-20s %-10s %-22s\n" "TENANT ID" "ENGINE" "PORT" "LIMITS" "CONTAINER NAME" "STATUS" "STORAGE SIZE"
    echo "========================================================================================================="

    for tid in $(jq -r '.tenants | keys[]' "$TENANTS_FILE"); do
        local engine port cpu mem cname status mount size
        engine=$(get_tenant_field "$tid" "engine")
        port=$(get_tenant_field "$tid" "port")
        cpu=$(get_tenant_field "$tid" "cpu_limit")
        mem=$(get_tenant_field "$tid" "mem_limit")
        cname=$(get_tenant_field "$tid" "container_name")
        mount=$(get_tenant_field "$tid" "mount_path")

        if docker ps --format '{{.Names}}' | grep -q "^${cname}$"; then
            status="RUNNING"
        elif docker ps -a --format '{{.Names}}' | grep -q "^${cname}$"; then
            status="STOPPED"
        else
            status="OFFLINE"
        fi

        size="0B"
        if [ -d "$mount" ]; then
            size=$(du -sh "$mount" 2>/dev/null | cut -f1 || echo "0B")
        fi

        printf "%-12s %-8s %-6s %-10s %-20s %-10s %-22s\n" "$tid" "$engine" "$port" "${cpu}c/${mem}" "$cname" "$status" "$size ($mount)"
    done
    echo "========================================================================================================="
}

# Real-time stats
cmd_stats() {
    local TENANT_ID="$1"
    if [ -n "$TENANT_ID" ]; then
        local cname
        cname=$(get_tenant_field "$TENANT_ID" "container_name")
        if [ -z "$cname" ]; then
            echo "[ERROR] Tenant '$TENANT_ID' not found in registry."
            exit 1
        fi
        docker stats --no-stream "$cname"
    else
        local CONTAINERS=()
        for c in $(jq -r '.tenants[].container_name' "$TENANTS_FILE" 2>/dev/null); do
            if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
                CONTAINERS+=("$c")
            fi
        done
        if [ ${#CONTAINERS[@]} -eq 0 ]; then
            echo "[INFO] No running tenant containers found."
            return 0
        fi
        docker stats --no-stream "${CONTAINERS[@]}"
    fi
}

# Start a stopped tenant
cmd_start() {
    local TENANT_ID="$1"
    local cname
    cname=$(get_tenant_field "$TENANT_ID" "container_name")
    if [ -z "$cname" ]; then
        echo "[ERROR] Tenant '$TENANT_ID' not found."
        exit 1
    fi
    echo "[INFO] Starting tenant '$TENANT_ID' ($cname)..."
    docker start "$cname"
    echo "[SUCCESS] Tenant '$TENANT_ID' started."
}

# Stop an active tenant
cmd_stop() {
    local TENANT_ID="$1"
    local cname
    cname=$(get_tenant_field "$TENANT_ID" "container_name")
    if [ -z "$cname" ]; then
        echo "[ERROR] Tenant '$TENANT_ID' not found."
        exit 1
    fi
    echo "[INFO] Stopping tenant '$TENANT_ID' ($cname)..."
    docker stop "$cname"
    echo "[SUCCESS] Tenant '$TENANT_ID' stopped."
}

# Restart tenant
cmd_restart() {
    local TENANT_ID="$1"
    local cname
    cname=$(get_tenant_field "$TENANT_ID" "container_name")
    if [ -z "$cname" ]; then
        echo "[ERROR] Tenant '$TENANT_ID' not found."
        exit 1
    fi
    echo "[INFO] Restarting tenant '$TENANT_ID' ($cname)..."
    docker restart "$cname"
    echo "[SUCCESS] Tenant '$TENANT_ID' restarted."
}

# Exec command in tenant container
cmd_exec() {
    local TENANT_ID="$1"
    shift || true
    local cname
    cname=$(get_tenant_field "$TENANT_ID" "container_name")
    local user
    user=$(get_tenant_field "$TENANT_ID" "username")
    if [ -z "$cname" ]; then
        echo "[ERROR] Tenant '$TENANT_ID' not found."
        exit 1
    fi
    docker exec -it -u "$user" "$cname" "$@"
}

# Snapshot individual tenant
cmd_snapshot() {
    local TENANT_ID="$1"
    local OUT_FILE="$2"
    local mount
    mount=$(get_tenant_field "$TENANT_ID" "mount_path")
    if [ -z "$mount" ] || [ ! -d "$mount" ]; then
        echo "[ERROR] Tenant '$TENANT_ID' storage mount not found."
        exit 1
    fi

    local SNAPSHOT_DIR="$BASE_DIR/snapshots"
    mkdir -p "$SNAPSHOT_DIR"

    if [ -z "$OUT_FILE" ]; then
        local TIMESTAMP
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        OUT_FILE="$SNAPSHOT_DIR/snapshot_${TENANT_ID}_${TIMESTAMP}.tar.gz"
    fi

    echo "[INFO] Creating snapshot for tenant '$TENANT_ID'..."
    tar -czf "$OUT_FILE" \
        --exclude='*/node_modules/.cache' \
        --exclude='*/target/debug' \
        --exclude='*/target/release' \
        --exclude='*/.cache' \
        --exclude='*/tmp/*' \
        -C "$MOUNTS_BASE" "$TENANT_ID"

    # Compute SHA-256
    local CHECKSUM
    CHECKSUM=$(sha256sum "$OUT_FILE" | cut -d ' ' -f 1)
    echo "$CHECKSUM  $(basename "$OUT_FILE")" > "${OUT_FILE}.sha256"

    # Metadata file
    cat << META_EOF > "${OUT_FILE}.meta.json"
{
  "tenant_id": "$TENANT_ID",
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "archive": "$(basename "$OUT_FILE")",
  "sha256": "$CHECKSUM",
  "engine": "$(get_tenant_field "$TENANT_ID" "engine")",
  "port": $(get_tenant_field "$TENANT_ID" "port")
}
META_EOF

    echo "[SUCCESS] Tenant snapshot saved: $OUT_FILE"
    echo "SHA-256: $CHECKSUM"
}

# Restore individual tenant
cmd_restore() {
    local TENANT_ID="$1"
    local ARCHIVE_FILE="$2"

    if [ -z "$TENANT_ID" ] || [ -z "$ARCHIVE_FILE" ]; then
        echo "[ERROR] Usage: ./tenant.sh restore <tenant_id> <snapshot_archive.tar.gz>"
        exit 1
    fi

    if [ ! -f "$ARCHIVE_FILE" ]; then
        echo "[ERROR] Archive file '$ARCHIVE_FILE' not found."
        exit 1
    fi

    # Verify SHA-256 if companion file exists
    if [ -f "${ARCHIVE_FILE}.sha256" ]; then
        echo "[INFO] Verifying archive checksum..."
        local EXPECTED
        EXPECTED=$(cut -d ' ' -f 1 < "${ARCHIVE_FILE}.sha256")
        local ACTUAL
        ACTUAL=$(sha256sum "$ARCHIVE_FILE" | cut -d ' ' -f 1)
        if [ "$EXPECTED" != "$ACTUAL" ]; then
            echo "[ERROR] Checksum mismatch! Archive is corrupted."
            exit 1
        fi
        echo "[INFO] Checksum verified: $ACTUAL"
    fi

    local mount="$MOUNTS_BASE/$TENANT_ID"
    echo "[INFO] Restoring workspace for tenant '$TENANT_ID'..."
    mkdir -p "$MOUNTS_BASE"
    rm -rf "$mount"
    tar -xzf "$ARCHIVE_FILE" -C "$MOUNTS_BASE"

    echo "[SUCCESS] Tenant workspace '$TENANT_ID' restored successfully."
}

# Delete tenant
cmd_delete() {
    local TENANT_ID="$1"
    shift || true

    local pname
    pname=$(get_tenant_field "$TENANT_ID" "project_name")
    local mount
    mount=$(get_tenant_field "$TENANT_ID" "mount_path")

    if [ -z "$pname" ]; then
        echo "[ERROR] Tenant '$TENANT_ID' not found in registry."
        exit 1
    fi

    local DO_ARCHIVE=false
    local FORCE=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --archive)
                DO_ARCHIVE=true
                shift
                ;;
            -y|--yes|--force)
                FORCE=true
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    if [ "$FORCE" = false ]; then
        read -r -p "[CONFIRM] Permanently delete tenant '$TENANT_ID'? (y/N): " CONFIRM
        if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi

    local cname
    cname=$(get_tenant_field "$TENANT_ID" "container_name")
    echo "[INFO] Tearing down tenant container $cname..."
    docker rm -f "$cname" 2>/dev/null || true

    # Clean up workspace
    if [ -d "$mount" ]; then
        rm -rf "$mount"
    fi

    # Remove from registry
    local TMP_JSON
    TMP_JSON=$(mktemp)
    jq --arg tid "$TENANT_ID" 'del(.tenants[$tid])' "$TENANTS_FILE" > "$TMP_JSON" && mv "$TMP_JSON" "$TENANTS_FILE"

    echo "[SUCCESS] Tenant '$TENANT_ID' deleted."
}

# Main Command Dispatcher
case "$1" in
    add)
        shift
        cmd_add "$@"
        ;;
    list|ls)
        cmd_list
        ;;
    stats)
        shift
        cmd_stats "$@"
        ;;
    start)
        shift
        cmd_start "$@"
        ;;
    stop)
        shift
        cmd_stop "$@"
        ;;
    restart)
        shift
        cmd_restart "$@"
        ;;
    exec)
        shift
        cmd_exec "$@"
        ;;
    snapshot)
        shift
        cmd_snapshot "$@"
        ;;
    restore)
        shift
        cmd_restore "$@"
        ;;
    delete|rm)
        shift
        cmd_delete "$@"
        ;;
    help|-h|--help|"")
        show_help
        ;;
    *)
        echo "[ERROR] Unknown command: $1"
        show_help
        exit 1
        ;;
esac
