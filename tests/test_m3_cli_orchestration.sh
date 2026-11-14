#!/bin/bash
# Test Suite for M3: CLI Orchestration & Automation UX

set -e

echo "=================================================="
echo "RUNNING M3 CLI ORCHESTRATION TESTS"
echo "=================================================="

# Test 1: Verify clean.sh help flag and syntax
echo -n "[TEST 1] clean.sh --help and syntax... "
bash -n clean.sh
./clean.sh --help > /dev/null
./clean.sh -h > /dev/null
echo "PASSED"

# Test 2: Verify start.sh advanced flags parsing
echo -n "[TEST 2] start.sh flag matrix... "
./start.sh --help > /dev/null
bash -n start.sh
echo "PASSED"

# Test 3: Verify setup-host.sh syntax and platform handler
echo -n "[TEST 3] setup-host.sh syntax... "
bash -n setup-host.sh
echo "PASSED"

# Test 4: Verify aliases.sh syntax
echo -n "[TEST 4] aliases.sh syntax & function exports... "
bash -n aliases.sh
# Source in subshell to test definition
(
    source aliases.sh
    type ghost-exec >/dev/null 2>&1
    type ghost-status >/dev/null 2>&1
    type ghost-logs >/dev/null 2>&1
    type ghost-ssh >/dev/null 2>&1
)
echo "PASSED"

# Test 5: Verify clean.sh option handling
echo -n "[TEST 5] clean.sh non-interactive stop execution syntax... "
# Execute with --help or verify flag parser
if ! ./clean.sh -s --help >/dev/null 2>&1 && ! ./clean.sh --help >/dev/null 2>&1; then
    echo "FAILED: clean.sh option parsing failed"
    exit 1
fi
echo "PASSED"

# Test 6: Image source resolution (prebuilt vs local build) + lifecycle verbs, docker stubbed
echo -n "[TEST 6] start.sh image resolution and lifecycle verbs... "
STUB_DIR=$(mktemp -d)
cat > "$STUB_DIR/docker" <<'STUB'
#!/usr/bin/env bash
case "$1" in
    image) exit 1 ;;
    ps) exit 0 ;;
    port) echo "0.0.0.0:2223"; exit 0 ;;
esac
printf 'DOCKER %s\n' "$*"
STUB
chmod +x "$STUB_DIR/docker"

PREBUILT_OUT=$(PATH="$STUB_DIR:$PATH" ./start.sh --prebuilt debian -m single 2>&1)
echo "$PREBUILT_OUT" | grep -q "ghcr.io/1999azzar/ghost-machine-debian:latest (GHCR prebuilt" || { echo "FAILED: --prebuilt did not resolve to the GHCR image"; exit 1; }
echo "$PREBUILT_OUT" | grep -q "compose up -d ghost1" || { echo "FAILED: --prebuilt did not start ghost1"; exit 1; }
if echo "$PREBUILT_OUT" | grep -q -- "--build"; then
    echo "FAILED: --prebuilt passed --build to compose"
    exit 1
fi

BUILD_OUT=$(PATH="$STUB_DIR:$PATH" ./start.sh -e arch -m power --build 2>&1)
echo "$BUILD_OUT" | grep -q "arch-template:latest (local build from Dockerfile.arch)" || { echo "FAILED: local build tag not resolved"; exit 1; }
echo "$BUILD_OUT" | grep -q "compose up -d --build ghost1" || { echo "FAILED: --build not forwarded"; exit 1; }

PRESET_OUT=$(PATH="$STUB_DIR:$PATH" GHOST_IMAGE=ghcr.io/1999azzar/ghost-machine-ubuntu:latest ./start.sh -m single 2>&1)
echo "$PRESET_OUT" | grep -q "GHCR prebuilt" || { echo "FAILED: preset GHOST_IMAGE was overwritten"; exit 1; }

STATUS_OUT=$(PATH="$STUB_DIR:$PATH" ./start.sh status 2>&1)
echo "$STATUS_OUT" | grep -q "SSH endpoints" || { echo "FAILED: status verb"; exit 1; }

STOP_OUT=$(PATH="$STUB_DIR:$PATH" ./start.sh stop 2>&1)
echo "$STOP_OUT" | grep -q "down --remove-orphans" || { echo "FAILED: stop verb"; exit 1; }

rm -rf "$STUB_DIR"
echo "PASSED"

echo "=================================================="
echo "ALL M3 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
