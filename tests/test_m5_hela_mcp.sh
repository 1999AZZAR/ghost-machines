#!/bin/bash
# Test Suite for M5: HeLa MCP Ecosystem Integration (Headless-Server Profile), Harness CLIs & Conductor

set -e

echo "=================================================="
echo "RUNNING M5 HELA MCP ECOSYSTEM & HARNESS TESTS"
echo "=================================================="

# Test 1: Verify MCP ecosystem repository and headless-server profile
echo -n "[TEST 1] HeLa MCP repository & headless-server profile... "
ECOSYSTEM_DIR="${MCP_ECOSYSTEM_LOCAL_PATH:-/home/azzar/project/MCPservers/mcp-ecosystem}"
CLEANUP_TEMP=false

if [ ! -d "$ECOSYSTEM_DIR" ]; then
    ECOSYSTEM_DIR="/tmp/mcp-ecosystem"
    if [ ! -d "$ECOSYSTEM_DIR" ]; then
        git clone --depth=1 https://github.com/1999AZZAR/hela-mcp-ecosystem.git "$ECOSYSTEM_DIR" > /dev/null 2>&1
        CLEANUP_TEMP=true
    fi
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

# Test 3: Verify AI harnesses (OpenCode v2, Antigravity) and absence of codex/gemini/kilo
echo -n "[TEST 3] Harness installer (opencode v2, agy) is unpinned and refreshable... "
if ! grep -q "opencode.ai/v2/install" harness-update.sh; then
    echo "FAILED: harness-update.sh missing OpenCode v2 installer"
    exit 1
fi
if ! grep -q "antigravity.google/cli/install.sh" harness-update.sh; then
    echo "FAILED: harness-update.sh missing Antigravity CLI installer"
    exit 1
fi
if grep -qE "@[0-9]+\.[0-9]+\.[0-9]+|=[\"']?v?[0-9]+\.[0-9]+\.[0-9]+" harness-update.sh; then
    echo "FAILED: harness-update.sh pins a version"
    exit 1
fi
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "COPY harness-update.sh" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE does not ship harness-update.sh"
        exit 1
    fi
    if ! grep -q "/usr/local/bin/harness-update" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE does not run harness-update"
        exit 1
    fi
    if grep -q "@google/gemini-cli" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE still contains @google/gemini-cli"
        exit 1
    fi
    if grep -q "@kilocode/cli" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE still contains @kilocode/cli"
        exit 1
    fi
    if grep -q "@openai/codex" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE still contains @openai/codex"
        exit 1
    fi
done
echo "PASSED"

# Test 4: Verify docker compose config validation with MCP_ECOSYSTEM_LOCAL_PATH
echo -n "[TEST 4] docker compose config validation with MCP ecosystem mount... "
export MCP_ECOSYSTEM_LOCAL_PATH="$ECOSYSTEM_DIR"
docker compose config --quiet
echo "PASSED"

# Test 5: Verify test client generation for 2 harnesses (antigravity, opencode)
echo -n "[TEST 5] Test generate-config.mjs for Antigravity and OpenCode... "
(
    cd "$ECOSYSTEM_DIR"
    node scripts/generate-config.mjs headless-server --backend antigravity --stdout > /dev/null
    node scripts/generate-config.mjs headless-server --backend opencode --stdout > /dev/null
)
echo "PASSED"

# Test 6: Verify Google Conductor repository setup across Dockerfiles & entrypoint
echo -n "[TEST 6] Google Conductor plugin and skills integration... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if ! grep -q "conductor.git" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing conductor.git clone"
        exit 1
    fi
    if ! grep -q "conductor-setup" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing conductor-setup skill link"
        exit 1
    fi
done
if ! grep -q "setup_user_harnesses_and_conductor" entrypoint.sh; then
    echo "FAILED: entrypoint.sh missing setup_user_harnesses_and_conductor"
    exit 1
fi
echo "PASSED"

# Test 7: RTK Universal Auto-Rewrite Hook Verification
echo -n "[TEST 7] RTK Universal Auto-Rewrite Hook verification... "
grep -q "rtk-rewrite.sh" entrypoint.sh
grep -q "PreToolUse" entrypoint.sh
echo "PASSED"

# Test 8: Runtime harness refresh wiring (entrypoint + compose un-shadowing)
echo -n "[TEST 8] Runtime harness refresh wiring... "
grep -q "refresh_builtin_harnesses" entrypoint.sh || { echo "FAILED: entrypoint lacks refresh hook"; exit 1; }
grep -q "GHOST_HARNESS_UPDATE" entrypoint.sh || { echo "FAILED: entrypoint ignores GHOST_HARNESS_UPDATE"; exit 1; }
grep -q "GHOST_HARNESS_UPDATE" docker-compose.yml || { echo "FAILED: compose does not pass GHOST_HARNESS_UPDATE"; exit 1; }
grep -q "agy-host" docker-compose.yml || { echo "FAILED: compose still shadows built-in agy"; exit 1; }
grep -q "update-harness" start.sh || { echo "FAILED: start.sh missing --update-harness"; exit 1; }
bash -n harness-update.sh || { echo "FAILED: harness-update.sh has a syntax error"; exit 1; }
echo "PASSED"

# Cleanup temporary clone if created for CI
if [ "$CLEANUP_TEMP" = true ]; then
    rm -rf /tmp/mcp-ecosystem
fi

echo "=================================================="
echo "ALL M5 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
