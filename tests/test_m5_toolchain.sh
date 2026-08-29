#!/bin/bash
# Test Suite for M5 Part 2: Modern Python (uv/pipx) & Rust Toolchains

set -e

echo "=================================================="
echo "RUNNING M5 MODERN TOOLCHAIN (UV, PIPX, RUST) TESTS"
echo "=================================================="

# Test 1: Verify pipx in base packages
echo -n "[TEST 1] pipx package verification across Dockerfiles... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "pipx" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing pipx"
        exit 1
    fi
done
echo "PASSED"

# Test 2: Verify uv installer
echo -n "[TEST 2] uv runtime installer verification across Dockerfiles... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "astral.sh/uv" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing uv installer"
        exit 1
    fi
done
echo "PASSED"

# Test 3: Verify rustup minimal installation
echo -n "[TEST 3] rustup minimal profile installer across Dockerfiles... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "sh.rustup.rs" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing rustup installer"
        exit 1
    fi
    if ! grep -q "\-\-profile minimal" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing --profile minimal for rustup"
        exit 1
    fi
done
echo "PASSED"

# Test 4: Verify PATH includes cargo and local bin
echo -n "[TEST 4] PATH verification for cargo and local bin... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "cargo/bin" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing cargo/bin in PATH"
        exit 1
    fi
    if ! grep -q "local/bin" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing local/bin in PATH"
        exit 1
    fi
done
echo "PASSED"

echo "=================================================="
echo "ALL M5 TOOLCHAIN TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
