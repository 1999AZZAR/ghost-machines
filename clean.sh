#!/bin/bash

# Ghost Machines: Environment Pruning Utility
# Standardizes the shutdown and cleanup of ghost environments.

echo "------------------------------------------------"
echo " GHOST MACHINES: CLEANUP"
echo "------------------------------------------------"
echo "1) Standard Stop  - Stop and remove containers/network"
echo "2) Deep Clean     - Stop and remove containers, networks, AND volumes"
echo "3) Reset Template - All of the above, plus remove the base image"
echo "4) Cancel"
echo "------------------------------------------------"
read -p "Select cleanup level [1-4]: " CHOICE

case $CHOICE in
    1)
        echo "[INFO] Performing standard stop..."
        docker compose --profile dual down
        ;;
    2)
        echo "[INFO] Performing deep clean (removing volumes)..."
        docker compose --profile dual down -v
        ;;
    3)
        echo "[INFO] Performing full reset (removing volumes and image)..."
        docker compose --profile dual down -v --rmi local
        ;;
    *)
        echo "Cleanup cancelled."
        exit 0
        ;;
esac

echo "[SUCCESS] Cleanup complete."
