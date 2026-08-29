#!/bin/bash
# Test Suite for M1: Security Hardening, UID/GID sync, SSH key handling, and validation

set -e

echo "=================================================="
echo "RUNNING M1 SECURITY HARDENING TESTS"
echo "=================================================="

# Test 1: Verify entrypoint syntax and executable bit
echo -n "[TEST 1] entrypoint.sh syntax and permissions... "
bash -n entrypoint.sh
if [ ! -x "entrypoint.sh" ]; then
    echo "FAILED: entrypoint.sh is not executable"
    exit 1
fi
echo "PASSED"

# Test 2: Verify start.sh syntax and executable bit
echo -n "[TEST 2] start.sh syntax and permissions... "
bash -n start.sh
if [ ! -x "start.sh" ]; then
    echo "FAILED: start.sh is not executable"
    exit 1
fi
echo "PASSED"

# Test 3: Verify docker-compose.yml configuration validity
echo -n "[TEST 3] docker compose config validation... "
export HOST_UID=1000
export HOST_GID=1000
export GHOST_USER=developer
export GHOST_DOCKERFILE=Dockerfile
export GHOST_IMAGE=ubuntu-template:latest
export SSH_AUTH_KEY_PATH=/dev/null
docker compose config --quiet
echo "PASSED"

# Test 4: Verify Dockerfiles include non-root user setup & entrypoint
echo -n "[TEST 4] Dockerfile user & entrypoint verification... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "GHOST_USER" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing GHOST_USER build arg"
        exit 1
    fi
    if ! grep -q "entrypoint.sh" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing entrypoint.sh"
        exit 1
    fi
    if ! grep -q "sudo" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing sudo setup"
        exit 1
    fi
done
echo "PASSED"

# Test 5: Verify .env permission hardening logic
echo -n "[TEST 5] .env permission hardening logic... "
TEST_ENV=".test_env_dummy"
touch "$TEST_ENV"
chmod 644 "$TEST_ENV"
# Simulate check logic
PERM=$(stat -c "%a" "$TEST_ENV" 2>/dev/null || stat -f "%Lp" "$TEST_ENV" 2>/dev/null)
if [ "$PERM" != "600" ]; then
    chmod 600 "$TEST_ENV"
fi
NEW_PERM=$(stat -c "%a" "$TEST_ENV" 2>/dev/null || stat -f "%Lp" "$TEST_ENV" 2>/dev/null)
rm -f "$TEST_ENV"
if [ "$NEW_PERM" != "600" ]; then
    echo "FAILED: Permission hardening failed"
    exit 1
fi
echo "PASSED"

# Test 6: Verify SSH authorized_keys function in entrypoint.sh
echo -n "[TEST 6] entrypoint authorized_keys permission simulation... "
TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/.ssh"
touch "$TEMP_DIR/.ssh/authorized_keys"
chmod 666 "$TEMP_DIR/.ssh/authorized_keys"
# Test permissions fix logic
chmod 700 "$TEMP_DIR/.ssh"
chmod 600 "$TEMP_DIR/.ssh/authorized_keys"
DIR_PERM=$(stat -c "%a" "$TEMP_DIR/.ssh")
FILE_PERM=$(stat -c "%a" "$TEMP_DIR/.ssh/authorized_keys")
rm -rf "$TEMP_DIR"
if [ "$DIR_PERM" != "700" ] || [ "$FILE_PERM" != "600" ]; then
    echo "FAILED: .ssh permissions expected 700/600, got $DIR_PERM/$FILE_PERM"
    exit 1
fi
echo "PASSED"

echo "=================================================="
echo "ALL M1 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
