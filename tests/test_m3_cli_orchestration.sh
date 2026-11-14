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

# Test 7: Nuke really nukes (tenants, all tags, volumes, networks, cache, registry)
echo -n "[TEST 7] clean.sh --nuke completeness... "
grep -q -- "--dry-run" clean.sh || { echo "FAILED: no --dry-run"; exit 1; }
grep -q "ghost-tenant-" clean.sh || { echo "FAILED: tenant projects not removed"; exit 1; }
grep -qF 'ghcr\.io/1999azzar/ghost-machine-' clean.sh || { echo "FAILED: GHCR tags not matched"; exit 1; }
grep -q "builder prune -af" clean.sh || { echo "FAILED: builder cache not fully pruned"; exit 1; }
grep -q "buildx prune" clean.sh || { echo "FAILED: buildx cache not pruned"; exit 1; }
grep -q "com.docker.compose.project" clean.sh || { echo "FAILED: volumes not scoped to this project"; exit 1; }
grep -q 'image prune -f --filter "label=' clean.sh || { echo "FAILED: dangling prune is not label-scoped"; exit 1; }
grep -q "config/tenants.json" clean.sh || { echo "FAILED: tenant registry not reset"; exit 1; }
grep -q "snapshots/" clean.sh || { echo "FAILED: --hard does not clear snapshots"; exit 1; }
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    grep -q "org.opencontainers.image.source" "$DOCKERFILE" || { echo "FAILED: $DOCKERFILE not labeled for scoped pruning"; exit 1; }
done
./clean.sh --nuke --dry-run > /tmp/ghost-nuke-dry.log 2>&1 || { echo "FAILED: --dry-run exited non-zero"; exit 1; }
grep -q "nothing was removed" /tmp/ghost-nuke-dry.log || { echo "FAILED: --dry-run did not report a no-op"; exit 1; }
grep -q "down --remove-orphans\|down -v --remove-orphans" /tmp/ghost-nuke-dry.log || { echo "FAILED: --dry-run did not show container teardown"; exit 1; }
rm -f /tmp/ghost-nuke-dry.log
if [ -n "$(git status --porcelain config/tenants.json)" ]; then
    echo "FAILED: --dry-run mutated the tenant registry"
    exit 1
fi
echo "PASSED"

# Test 8: Nuke command sequence against a stubbed docker
echo -n "[TEST 8] clean.sh --nuke command sequence... "
STUB_DIR=$(mktemp -d)
DOCKER_LOG=$(mktemp)
cat > "$STUB_DIR/docker" <<'STUB'
#!/usr/bin/env bash
echo "docker $*" >> "$DOCKER_LOG"
case "$1/$2" in
    images/--format)
        printf 'ghcr.io/1999azzar/ghost-machine-ubuntu:v2.1.0\nghcr.io/1999azzar/ghost-machine-ubuntu:latest\nubuntu-template:latest\nnginx:latest\n'
        ;;
    ps/-a)
        echo "ghost-tenant-alice"
        ;;
    network/ls)
        printf 'bridge\nhost\nghost_sandbox\n'
        ;;
    volume/ls)
        echo "ghostvol"
        ;;
    volume/inspect)
        echo "ghost-machines"
        ;;
    buildx/version)
        exit 0
        ;;
    system/df)
        echo "stub disk report"
        ;;
esac
exit 0
STUB
chmod +x "$STUB_DIR/docker"
cp config/tenants.json "${DOCKER_LOG}.registry"

PATH="$STUB_DIR:$PATH" DOCKER_LOG="$DOCKER_LOG" ./clean.sh --nuke -y > "${DOCKER_LOG}.out" 2>&1 || { echo "FAILED: nuke exited non-zero"; cat "${DOCKER_LOG}.out"; exit 1; }

assert_log() {
    grep -qF "$1" "$DOCKER_LOG" || { echo "FAILED: missing '$1'"; cat "$DOCKER_LOG"; exit 1; }
}
assert_absent() {
    if grep -qF "$1" "$DOCKER_LOG"; then echo "FAILED: unexpected '$1'"; exit 1; fi
}
assert_log "compose --profile dual --profile remote down -v --remove-orphans"
assert_log "compose -p ghost-tenant-alice -f templates/docker-compose.tenant.yml down -v"
assert_log "rmi -f ghcr.io/1999azzar/ghost-machine-ubuntu:v2.1.0"
assert_log "rmi -f ghcr.io/1999azzar/ghost-machine-ubuntu:latest"
assert_log "rmi -f ubuntu-template:latest"
assert_absent "rmi -f nginx:latest"
assert_log "image prune -f --filter label=org.opencontainers.image.source"
assert_log "volume rm -f ghostvol"
assert_log "network rm ghost_sandbox"
assert_log "builder prune -af"
assert_log "buildx prune -af"
grep -q '"tenants": {}' config/tenants.json || { echo "FAILED: tenant registry not reset"; exit 1; }

cp "${DOCKER_LOG}.registry" config/tenants.json
rm -rf "$STUB_DIR" "$DOCKER_LOG" "${DOCKER_LOG}.out" "${DOCKER_LOG}.registry"
echo "PASSED"

echo "=================================================="
echo "ALL M3 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
