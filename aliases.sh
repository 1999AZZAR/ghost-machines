# ==============================================================================
# Ghost Machines Connection & Management Aliases
# Add these to your ~/.bashrc or ~/.zshrc: source /path/to/ghost-machines/aliases.sh
# ==============================================================================

# Quick Interactive Shell Access
alias start-ghost='docker exec -it $(docker ps --filter "name=ghost-machine" --format "{{.Names}}" | head -n 1) /bin/bash'
alias start-ghost1='docker exec -it ghost-machine1 /bin/bash'
alias start-ghost2='docker exec -it ghost-machine2 /bin/bash'

# Execute Command in Ghost Machine
# Usage: ghost-exec [command...] (in first active ghost machine)
# Usage: ghost-exec <container_name> [command...]
ghost-exec() {
    local TARGET
    if [ $# -eq 0 ]; then
        echo "Usage: ghost-exec [container_name] <command>"
        return 1
    fi
    if docker ps --format '{{.Names}}' | grep -q "^$1$"; then
        TARGET="$1"
        shift
    else
        TARGET="$(docker ps --filter "name=ghost-machine" --format '{{.Names}}' | head -n 1)"
    fi
    if [ -z "$TARGET" ]; then
        echo "[ERROR] No active ghost machines found."
        return 1
    fi
    docker exec -it "$TARGET" "$@"
}

# Display Status of Active Ghost Machines
ghost-status() {
    echo "=================================================="
    echo " GHOST MACHINES STATUS"
    echo "=================================================="
    docker ps --filter "name=ghost" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
    echo ""
    echo "Resource Utilization:"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}" $(docker ps --filter "name=ghost" -q) 2>/dev/null || echo "  (No running containers)"
    echo "=================================================="
}

# View Logs for Ghost Machines
# Usage: ghost-logs [container_name]
ghost-logs() {
    local TARGET="${1:-$(docker ps --filter "name=ghost-machine" --format '{{.Names}}' | head -n 1)}"
    if [ -z "$TARGET" ]; then
        echo "[ERROR] No active ghost machines found."
        return 1
    fi
    docker logs -f "$TARGET"
}

# SSH Helper
# Usage: ghost-ssh [1|2|single|power|half] [user]
ghost-ssh() {
    local TARGET="${1:-1}"
    local USER="${2:-developer}"
    local PORT="2223"
    case "$TARGET" in
        1|ghost1|ghost-machine1) PORT="${G1_PORT:-2223}" ;;
        2|ghost2|ghost-machine2) PORT="${G2_PORT:-2224}" ;;
        single|ghost-machine-single) PORT="${G1_PORT:-2223}" ;;
        power|ghost-machine-power) PORT="${G1_PORT:-2223}" ;;
        half|ghost-machine-half) PORT="${G1_PORT:-2223}" ;;
        *) PORT="$TARGET" ;;
    esac
    echo "[INFO] Connecting via SSH to $USER@localhost:$PORT..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$PORT" "$USER@localhost"
}
