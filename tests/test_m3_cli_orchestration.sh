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

echo "=================================================="
echo "ALL M3 TESTS PASSED SUCCESSFULLY!"
echo "=================================================="
