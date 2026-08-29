#!/bin/bash
# Test Suite for M5: HeLa MCP Ecosystem Integration (Headless-Server Profile) & Harness CLIs

set -e

echo "=================================================="
echo "RUNNING M5 HELA MCP ECOSYSTEM & HARNESS TESTS"
echo "=================================================="

# Test 1: Verify local MCP ecosystem repository and headless-server profile
echo -n "[TEST 1] Local HeLa MCP repository & headless-server profile... "
ECOSYSTEM_DIR="/home/azzar/project/MCPservers/mcp-ecosystem"
if [ ! -d "$ECOSYSTEM_DIR" ]; then
    echo "FAILED: Local directory $ECOSYSTEM_DIR not found"
    exit 1
fi
if [ ! -f "$ECOSYSTEM_DIR/config/profiles.json" ]; then
    echo "FAILED: profiles.json missing in $ECOSYSTEM_DIR"
    exit 1
fi
# Verify profile exists
grep -q '"id": "headless-server"' "$ECOSYSTEM_DIR/config/profiles.json"
echo "PASSED"

# Test 2: Verify Dockerfiles clone and build headless-server profile
echo -n "[TEST 2] Dockerfile HeLa MCP ecosystem directives... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "hela-mcp-ecosystem" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing hela-mcp-ecosystem clone"
        exit 1
    fi
    if ! grep -q "\-\-profile headless-server" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing --profile headless-server"
        exit 1
    fi
    for MCP_BIN in mcp-mitosis mcp-genome mcp-membrane mcp-nucleus mcp-ribosome mcp-enzyme mcp-phenotype; do
        if ! grep -q "$MCP_BIN" "$DOCKERFILE"; then
            echo "FAILED: $DOCKERFILE missing binary wrapper for $MCP_BIN"
            exit 1
        fi
    done
done
echo "PASSED"

# Test 3: Verify AI harnesses (Kilo, OpenCode, Antigravity) across Dockerfiles
echo -n "[TEST 3] Dockerfile AI harness packages (@kilocode/cli, opencode-ai, agy)... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "@kilocode/cli" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing @kilocode/cli"
        exit 1
    fi
    if ! grep -q "opencode-ai" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing opencode-ai"
        exit 1
    fi
    if ! grep -q "agy" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing agy CLI setup"
        exit 1
    fi
done
echo "PASSED"

# Test 4: Verify docker compose config validation with MCP_ECOSYSTEM_LOCAL_PATH
echo -n "[TEST 4] docker compose config validation with MCP ecosystem mount... "
export MCP_ECOSYSTEM_LOCAL_PATH="/home/azzar/project/MCPservers/mcp-ecosystem"
docker compose config --quiet
echo "PASSED"

# Test 5: Verify test client generation via local ecosystem generator
echo -n "[TEST 5] Test generate-config.mjs with headless-server profile... "
(
    cd "$ECOSYSTEM_DIR"
    node scripts/generate-config.mjs headless-server --backend antigravity --stdout > /dev/null
)
echo "PASSED"

echo "=================================================="
echo "ALL M5 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
