#!/bin/bash

# Ghost Machines: Environment Pruning Utility
# Standardizes the shutdown and cleanup of ghost environments.
# Supports both interactive menu and headless CLI flags.

set -e

LEVEL=""
FORCE=false

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
        -y|--yes|--force)
            FORCE=true
            shift
            ;;
        -h|--help)
            echo "Ghost Machines — Cleanup Utility"
            echo ""
            echo "Usage: ./clean.sh [options]"
            echo ""
            echo "Options:"
            echo "  -s, --stop           Stop and remove containers/network (Level 1)"
            echo "  -v, --volumes, --deep Stop and remove containers, networks, AND volumes (Level 2)"
            echo "  -a, --all, --reset   All of above, plus remove local images (Level 3)"
            echo "  -y, --yes, --force   Skip confirmation prompts"
            echo "  -h, --help           Show this help message"
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
    echo "1) Standard Stop  - Stop and remove containers/network"
    echo "2) Deep Clean     - Stop and remove containers, networks, AND volumes"
    echo "3) Reset Template - All of the above, plus remove the base image"
    echo "4) Cancel"
    echo "------------------------------------------------"
    read -p "Select cleanup level [1-4]: " LEVEL
fi

case $LEVEL in
    1)
        echo "[INFO] Performing standard stop..."
        docker compose --profile dual --profile remote down
        ;;
    2)
        if [ "$FORCE" = false ]; then
            read -p "[WARNING] This will remove container volumes. Continue? (y/n): " CONFIRM
            if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then echo "Cleanup cancelled."; exit 0; fi
        fi
        echo "[INFO] Performing deep clean (removing volumes)..."
        docker compose --profile dual --profile remote down -v
        ;;
    3)
        if [ "$FORCE" = false ]; then
            read -p "[WARNING] This will remove containers, volumes, AND local images. Continue? (y/n): " CONFIRM
            if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then echo "Cleanup cancelled."; exit 0; fi
        fi
        echo "[INFO] Performing full reset (removing volumes and image)..."
        docker compose --profile dual --profile remote down -v --rmi local
        ;;
    *)
        echo "Cleanup cancelled."
        exit 0
        ;;
esac

echo "[SUCCESS] Cleanup complete."
