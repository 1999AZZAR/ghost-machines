#!/bin/bash
# Test Suite for M6: Multi-Tenant Workspace-as-a-Service (tenant.sh)

set -e

echo "=================================================="
echo "RUNNING M6 MULTI-TENANT WORKSPACE ORCHESTRATION TESTS"
echo "=================================================="

# Test 1: Help flags and syntax
echo -n "[TEST 1] tenant.sh --help and syntax validation... "
./tenant.sh --help > /dev/null
bash -n tenant.sh
echo "PASSED"

# Test 2: List empty tenants
echo -n "[TEST 2] tenant.sh list with clean registry... "
./tenant.sh list > /dev/null
echo "PASSED"

# Test 3: Provision 2 concurrent test tenants
echo -n "[TEST 3] Provisioning 2 isolated tenants (test_alice, test_bob)... "
./tenant.sh add test_alice --engine debian --port 2291 --cpu 1.0 --mem 1G > /dev/null
./tenant.sh add test_bob --engine debian --port 2292 --cpu 1.0 --mem 1G > /dev/null

# Verify registry has both tenants
grep -q '"test_alice"' config/tenants.json
grep -q '"test_bob"' config/tenants.json

# Verify both containers exist
docker ps --format '{{.Names}}' | grep -q "ghost-tenant-test_alice"
docker ps --format '{{.Names}}' | grep -q "ghost-tenant-test_bob"
echo "PASSED"

# Test 4: Workspace Storage Isolation
echo -n "[TEST 4] Verifying workspace storage isolation... "
echo "secret_alice_token_123" > mounts/tenants/test_alice/alice_secret.txt

if [ -f mounts/tenants/test_bob/alice_secret.txt ]; then
    echo "FAILED: Cross-tenant data leakage detected!"
    exit 1
fi
echo "PASSED"

# Test 5: Tenant-specific Snapshot & Checksum
echo -n "[TEST 5] Individual tenant snapshot and integrity check... "
./tenant.sh snapshot test_alice > /dev/null
SNAP_FILE=$(ls -t snapshots/snapshot_test_alice_*.tar.gz 2>/dev/null | head -n 1)
if [ ! -f "$SNAP_FILE" ] || [ ! -f "${SNAP_FILE}.sha256" ] || [ ! -f "${SNAP_FILE}.meta.json" ]; then
    echo "FAILED: Snapshot files missing for test_alice"
    exit 1
fi
grep -q "test_alice" "${SNAP_FILE}.meta.json"
echo "PASSED"

# Test 6: Independent Lifecycle (Stop alice, bob remains running)
echo -n "[TEST 6] Independent lifecycle (stopping alice keeps bob active)... "
./tenant.sh stop test_alice > /dev/null

if docker ps --format '{{.Names}}' | grep -q "^ghost-tenant-test_alice$"; then
    echo "FAILED: test_alice should be stopped"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q "^ghost-tenant-test_bob$"; then
    echo "FAILED: test_bob should still be running"
    exit 1
fi
echo "PASSED"

# Test 7: Clean Teardown of Tenants
echo -n "[TEST 7] Clean teardown and registry cleanup... "
./tenant.sh delete test_alice -y > /dev/null
./tenant.sh delete test_bob -y > /dev/null

if docker ps -a --format '{{.Names}}' | grep -q "ghost-tenant-test_alice"; then
    echo "FAILED: ghost-tenant-test_alice container still exists"
    exit 1
fi
if docker ps -a --format '{{.Names}}' | grep -q "ghost-tenant-test_bob"; then
    echo "FAILED: ghost-tenant-test_bob container still exists"
    exit 1
fi

# Cleanup test snapshots
rm -f "$SNAP_FILE" "${SNAP_FILE}.sha256" "${SNAP_FILE}.meta.json"

echo "PASSED"

echo "=================================================="
echo "ALL M6 MULTI-TENANT TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
