#!/bin/bash
# Test Suite for M4: Resilient State & Smart Snapshot Management

set -e

echo "=================================================="
echo "RUNNING M4 SMART SNAPSHOT & RESTORE TESTS"
echo "=================================================="

# Test 1: Help flags
echo -n "[TEST 1] snapshot.sh and restore.sh --help flags... "
./snapshot.sh --help > /dev/null
./restore.sh --help > /dev/null
echo "PASSED"

# Create isolated sandbox test workspace
SANDBOX_DIR=$(mktemp -d)
trap 'rm -rf "$SANDBOX_DIR"' EXIT

cp snapshot.sh restore.sh "$SANDBOX_DIR/"
ORIG_PWD=$(pwd)
cd "$SANDBOX_DIR"
mkdir -p mounts/ubuntu1/node_modules/.cache
mkdir -p mounts/ubuntu1/src
echo "console.log('test');" > mounts/ubuntu1/src/index.js
echo "cache_data" > mounts/ubuntu1/node_modules/.cache/cache.json

# Test 2: Smart Cache Exclusion
echo -n "[TEST 2] Snapshot creation with smart cache exclusion... "
TEST_SNAPSHOT="test_snap_$(date +%s).tar.gz"

./snapshot.sh -o "$TEST_SNAPSHOT" > /dev/null

# Verify archive exists
if [ ! -f "$TEST_SNAPSHOT" ]; then
    echo "FAILED: Snapshot file not created"
    exit 1
fi

# Verify cache exclusion in tar contents
if tar -tzf "$TEST_SNAPSHOT" | grep -q "node_modules/.cache"; then
    echo "FAILED: Cache directory was not excluded"
    exit 1
fi

# Verify legitimate files are included
if ! tar -tzf "$TEST_SNAPSHOT" | grep -q "src/index.js"; then
    echo "FAILED: Valid source file missing from archive"
    exit 1
fi
echo "PASSED"

# Test 3: Checksum and Metadata Verification
echo -n "[TEST 3] Companion .sha256 and .meta.json verification... "
if [ ! -f "${TEST_SNAPSHOT}.sha256" ]; then
    echo "FAILED: .sha256 checksum file missing"
    exit 1
fi
if [ ! -f "${TEST_SNAPSHOT}.meta.json" ]; then
    echo "FAILED: .meta.json metadata file missing"
    exit 1
fi
sha256sum -c "${TEST_SNAPSHOT}.sha256" > /dev/null
node -e "JSON.parse(require('fs').readFileSync('${TEST_SNAPSHOT}.meta.json', 'utf8'))"
echo "PASSED"

# Test 4: Safe Non-Interactive Restore
echo -n "[TEST 4] Safe non-interactive restore (--force)... "
# Modify mounts to simulate drift
echo "drifted" > mounts/ubuntu1/src/drift.txt
./restore.sh --force "$TEST_SNAPSHOT" > /dev/null

# Verify index.js restored and drift removed
if [ ! -f "mounts/ubuntu1/src/index.js" ]; then
    echo "FAILED: index.js missing after restore"
    exit 1
fi
if [ -f "mounts/ubuntu1/src/drift.txt" ]; then
    echo "FAILED: Drift file still present after clean restore"
    exit 1
fi
echo "PASSED"

# Test 5: Atomic Rollback on Corrupted Archive
echo -n "[TEST 5] Atomic rollback on corrupted archive... "
CORRUPT_SNAP="test_corrupt.tar.gz"
echo "THIS IS CORRUPT NOT A GZIP ARCHIVE" > "$CORRUPT_SNAP"
echo "preserved_state" > mounts/ubuntu1/src/keep_me.txt

# Run restore on corrupt archive (expect failure)
set +e
./restore.sh --force "$CORRUPT_SNAP" > /dev/null 2>&1
RESTORE_STATUS=$?
set -e

if [ $RESTORE_STATUS -eq 0 ]; then
    echo "FAILED: Corrupted archive restore should have failed"
    exit 1
fi

# Verify previous state was preserved by atomic rollback
if [ ! -f "mounts/ubuntu1/src/keep_me.txt" ]; then
    echo "FAILED: Atomic rollback failed to preserve original files"
    exit 1
fi
echo "PASSED"

cd "$ORIG_PWD"

echo "=================================================="
echo "ALL M4 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
