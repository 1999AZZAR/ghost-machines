#!/bin/bash
# Test Suite for M2: Multi-Engine Parity & Image Optimization

set -e

echo "=================================================="
echo "RUNNING M2 MULTI-ENGINE & OPTIMIZATION TESTS"
echo "=================================================="

# Test 1: Verify help flag in start.sh
echo -n "[TEST 1] start.sh --help flag... "
./start.sh --help > /dev/null
echo "PASSED"

# Test 2: Verify version arguments in all Dockerfiles
echo -n "[TEST 2] Dockerfile version build ARGs... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    for VAR in GO_VERSION HELIX_VERSION LAZYGIT_VERSION; do
        if ! grep -q "$VAR" "$DOCKERFILE"; then
            echo "FAILED: $DOCKERFILE missing $VAR"
            exit 1
        fi
    done
done
echo "PASSED"

# Test 3: Verify package cache cleanup in Debian/Ubuntu Dockerfiles
echo -n "[TEST 3] Debian/Ubuntu apt cache cleanup... "
for DOCKERFILE in Dockerfile Dockerfile.debian; do
    if ! grep -q "apt-get clean" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing apt-get clean"
        exit 1
    fi
    if ! grep -q "rm -rf /var/lib/apt/lists/\*" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing lists cleanup"
        exit 1
    fi
done
echo "PASSED"

# Test 4: Verify Alpine apk cache cleanup
echo -n "[TEST 4] Alpine apk cache cleanup... "
if ! grep -q "rm -rf /var/cache/apk/\*" Dockerfile.alpine; then
    echo "FAILED: Dockerfile.alpine missing apk cache cleanup"
    exit 1
fi
echo "PASSED"

# Test 5: Verify Arch pacman cache cleanup
echo -n "[TEST 5] Arch pacman cache cleanup... "
if ! grep -q "pacman -Scc --noconfirm" Dockerfile.arch; then
    echo "FAILED: Dockerfile.arch missing pacman -Scc"
    exit 1
fi
echo "PASSED"

# Test 6: Verify npm cache cleanup
echo -n "[TEST 6] npm cache cleanup across Dockerfiles... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "npm cache clean --force" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing npm cache clean"
        exit 1
    fi
done
echo "PASSED"

# Test 7: Verify docker compose config for all 4 engines
echo -n "[TEST 7] docker compose config validation for all engines... "
for ENGINE in ubuntu debian alpine arch; do
    case $ENGINE in
        ubuntu) DFILE="Dockerfile"; IMG="ubuntu-template:latest" ;;
        debian) DFILE="Dockerfile.debian"; IMG="debian-template:latest" ;;
        alpine) DFILE="Dockerfile.alpine"; IMG="alpine-template:latest" ;;
        arch)   DFILE="Dockerfile.arch"; IMG="arch-template:latest" ;;
    esac
    GHOST_DOCKERFILE="$DFILE" GHOST_IMAGE="$IMG" docker compose config --quiet
done
echo "PASSED"

echo "=================================================="
echo "ALL M2 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
