#!/bin/bash

# Ghost Machines: Environment Pruning Utility
# Four levels, from "stop the containers" to "return this checkout to pristine".
# Supports interactive menu, headless flags, and a --dry-run preview.

set -e

LEVEL=""
FORCE=false
HARD=false
DRY_RUN=false
TENANT_TEMPLATE="templates/docker-compose.tenant.yml"

# --- helpers ------------------------------------------------------------------

run() {
    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] $*"
    else
        "$@"
    fi
}

# Local build tags: exactly the four engine images this repo produces.
local_template_images() {
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
        | grep -E '^(ubuntu|debian|alpine|arch)-template:' || true
}

# Every image this project can produce or pull: local templates plus all GHCR
# tags (latest, vX.Y.Z, latest-<sha>), regardless of how they were tagged.
ghost_images() {
    docker images --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
        | grep -E '^(ghcr\.io/1999azzar/ghost-machine-[a-z0-9-]+|(ubuntu|debian|alpine|arch)-template):' || true
}

ghost_containers() {
    for FILTER in "name=ghost-machine" "name=ghost-tenant-" "name=ghost-tunnel"; do
        docker ps -aq --filter "$FILTER" 2>/dev/null || true
    done | sort -u
}

ghost_networks() {
    docker network ls --format '{{.Name}}' 2>/dev/null \
        | grep -E '^(ghost_sandbox|ghost-machines_|ghost-tenant-)' || true
}

# Only volumes owned by a compose project of ours — never the host's other volumes.
ghost_volumes() {
    local VOLUME PROJECT
    for VOLUME in $(docker volume ls -q 2>/dev/null); do
        PROJECT=$(docker volume inspect -f '{{ index .Labels "com.docker.compose.project" }}' "$VOLUME" 2>/dev/null || true)
        case "$PROJECT" in
            ghost-machines|ghost-tenant-*) echo "$VOLUME" ;;
        esac
    done
}

tenant_projects() {
    docker ps -a --format '{{.Names}}' 2>/dev/null | grep -E '^ghost-tenant-' || true
}

reset_tenant_registry() {
    [ -f config/tenants.json ] || return 0
    if [ "$DRY_RUN" = true ]; then
        echo "    [dry-run] reset config/tenants.json to an empty registry"
        return 0
    fi
    # Prefer the committed content so a nuke leaves no spurious diff.
    if git ls-files --error-unmatch config/tenants.json >/dev/null 2>&1; then
        git checkout -- config/tenants.json 2>/dev/null && return 0
    fi
    printf '{\n  "version": "1.0",\n  "tenants": {}\n}\n' > config/tenants.json
}

warn_tenants_present() {
    local TENANTS
    TENANTS=$(tenant_projects)
    if [ -n "$TENANTS" ]; then
        echo "[NOTE] Tenant containers are still present:"
        while IFS= read -r TENANT; do
            [ -n "$TENANT" ] && echo "       - $TENANT"
        done <<< "$TENANTS"
        echo "       Remove them with ./tenant.sh delete <id> --archive, or use --nuke."
    fi
}

confirm() {
    [ "$FORCE" = true ] && return 0
    [ "$DRY_RUN" = true ] && return 0
    local ANSWER
    read -r -p "[WARNING] $1 Continue? (y/N): " ANSWER
    [[ "$ANSWER" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
}

# --- argument parsing ---------------------------------------------------------

while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--stop)
            LEVEL="1"
            shift
            ;;
        -v|--volumes|--deep)
            LEVEL="2"
            shift
            ;;
        -a|--all|--reset)
            LEVEL="3"
            shift
            ;;
        --nuke|-n|--purge)
            LEVEL="4"
            shift
            ;;
        --hard)
            HARD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -y|--yes|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Ghost Machines — Cleanup Utility"
            echo ""
            echo "Usage: ./clean.sh [options]"
            echo ""
            echo "Levels:"
            echo "  -s, --stop           L1: stop + remove containers and network"
            echo "  -v, --volumes        L2: L1 + volumes"
            echo "  -a, --all, --reset   L3: L2 + local template images (keeps pulled GHCR images)"
            echo "      --nuke, --purge  L4: L3 + tenant projects, every Ghost/GHCR image tag,"
            echo "                            Ghost volumes and networks, all builder cache,"
            echo "                            dangling images, and resets config/tenants.json"
            echo ""
            echo "Options:"
            echo "      --hard           With --nuke: also delete mounts/ and snapshots/ (data loss)"
            echo "      --dry-run        Print exactly what would be removed; change nothing"
            echo "  -y, --yes, --force   Skip confirmation prompts"
            echo "  -h, --help           Show this help message"
            echo ""
            echo "Examples:"
            echo "  ./clean.sh -s -y"
            echo "  ./clean.sh --nuke --dry-run"
            echo "  ./clean.sh --nuke -y"
            echo "  ./clean.sh --nuke --hard -y"
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$LEVEL" ]; then
    echo "------------------------------------------------"
    echo " GHOST MACHINES: CLEANUP"
    echo "------------------------------------------------"
    echo "1) Standard Stop  - Remove containers/network            (keeps images, work)"
    echo "2) Deep Clean     - 1 + remove volumes                   (keeps images, work)"
    echo "3) Reset Template - 2 + remove local template images     (keeps GHCR, work)"
    echo "4) Nuke           - 3 + tenants, ALL Ghost/GHCR images,"
    echo "                    volumes, networks, builder cache     (keeps mounts/)"
    echo "5) Cancel"
    echo "------------------------------------------------"
    read -r -p "Select cleanup level [1-5]: " LEVEL
fi

if [ "$HARD" = true ] && [ "$LEVEL" != "4" ]; then
    echo "[ERROR] --hard only applies to --nuke (Level 4)."
    exit 1
fi

case $LEVEL in
    1)
        echo "[INFO] L1 — stopping containers and removing the network..."
        run docker compose --profile dual --profile remote down --remove-orphans
        warn_tenants_present
        echo "[L1] Done. Images, volumes, mounts/ and .env are untouched."
        ;;
    2)
        confirm "This removes the containers' volumes (mounts/ on the host is untouched)."
        echo "[INFO] L2 — removing containers, network and volumes..."
        run docker compose --profile dual --profile remote down -v --remove-orphans
        warn_tenants_present
        echo "[L2] Done. Images and mounts/ are untouched."
        ;;
    3)
        confirm "This removes containers, volumes and the local template images."
        echo "[INFO] L3 — removing containers, volumes and local template images..."
        run docker compose --profile dual --profile remote down -v --remove-orphans
        for IMAGE in $(local_template_images); do
            run docker rmi -f "$IMAGE" >/dev/null 2>&1 || true
        done
        warn_tenants_present
        echo "[L3] Done. Pulled GHCR images and mounts/ are untouched."
        ;;
    4)
        echo "[INFO] L4 — nuke. This will remove:"
        echo "       - every Ghost container (main, tunnel, and tenant projects)"
        echo "       - every Ghost network and Ghost-owned volume"
        echo "       - every local template image AND every GHCR ghost-machine tag"
        echo "       - all builder/buildx cache (host-wide), and dangling images built from this project"
        echo "       - the tenant registry (config/tenants.json reset)"
        if [ "$HARD" = true ]; then
            echo "       - mounts/ and snapshots/ (--hard: WORK AND BACKUPS ARE DELETED)"
        else
            echo "       mounts/ and snapshots/ are KEPT (add --hard to delete them)"
        fi
        confirm "This is a destructive, irreversible operation."
        echo "[INFO] Removing containers, networks and volumes..."
        run docker compose --profile dual --profile remote down -v --remove-orphans 2>/dev/null || true

        for PROJECT in $(tenant_projects); do
            echo "       tenant project: $PROJECT"
            # Teardown must parse even when no tenant env vars are exported.
            run env TENANT_MOUNT_PATH="${TENANT_MOUNT_PATH:-/tmp/ghost-tenant-teardown}" \
                docker compose -p "$PROJECT" -f "$TENANT_TEMPLATE" down -v --remove-orphans >/dev/null 2>&1 \
                || run docker rm -f "$PROJECT" >/dev/null 2>&1 || true
        done
        for CONTAINER in $(ghost_containers); do
            run docker rm -f "$CONTAINER" >/dev/null 2>&1 || true
        done

        echo "[INFO] Removing images..."
        GHOST_IMAGE_LIST=$(ghost_images)
        if [ -z "$GHOST_IMAGE_LIST" ]; then
            echo "       (no Ghost images present)"
        else
            for IMAGE in $GHOST_IMAGE_LIST; do
                echo "       $IMAGE"
                run docker rmi -f "$IMAGE" >/dev/null 2>&1 || true
            done
        fi
        run docker image prune -f --filter "label=org.opencontainers.image.source=https://github.com/1999AZZAR/ghost-machines" >/dev/null 2>&1 || true

        echo "[INFO] Removing volumes and networks..."
        for VOLUME in $(ghost_volumes); do
            run docker volume rm -f "$VOLUME" >/dev/null 2>&1 || true
        done
        for NETWORK in $(ghost_networks); do
            run docker network rm "$NETWORK" >/dev/null 2>&1 || true
        done

        echo "[INFO] Clearing build cache (host-wide: Docker cannot scope build cache per project)..."
        run docker builder prune -af >/dev/null 2>&1 || true
        if docker buildx version >/dev/null 2>&1; then
            run docker buildx prune -af >/dev/null 2>&1 || true
        fi

        echo "[INFO] Resetting tenant registry..."
        reset_tenant_registry

        if [ "$HARD" = true ]; then
            echo "[INFO] Hard nuke: wiping mounts/ and snapshots/..."
            if [ "$DRY_RUN" = true ]; then
                echo "    [dry-run] rm -rf mounts/ubuntu1 mounts/ubuntu2 mounts/tenants snapshots/*.tar.gz snapshots/*.sha256 snapshots/*.meta.json"
            else
                rm -rf mounts/ubuntu1 mounts/ubuntu2 mounts/tenants 2>/dev/null || true
                rm -f snapshots/*.tar.gz snapshots/*.sha256 snapshots/*.meta.json 2>/dev/null || true
                mkdir -p mounts/ubuntu1 mounts/ubuntu2 mounts/tenants snapshots
                touch mounts/ubuntu1/.gitkeep mounts/ubuntu2/.gitkeep mounts/tenants/.gitkeep snapshots/.gitkeep 2>/dev/null || true
            fi
        else
            echo "[NOTE] Build cache is shared by every Docker project on this host; --nuke clears it all."
            echo "[TIP] Add --hard to also delete mounts/ and snapshots/ (true 1st-user nuke)."
        fi

        echo ""
        if [ "$DRY_RUN" = true ]; then
            echo "[L4] Dry run complete — nothing was removed."
        else
            echo "[L4] Nuke complete. Remaining Docker footprint for Ghost:"
            docker system df 2>/dev/null || true
            echo "[L4] mounts/ kept? $([ "$HARD" = true ] && echo no || echo yes) · registry reset · rebuild with ./start.sh"
        fi
        ;;
    *)
        echo "Cleanup cancelled."
        exit 0
        ;;
esac

echo "[SUCCESS] Cleanup complete."
