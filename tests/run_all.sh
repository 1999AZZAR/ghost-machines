#!/bin/bash
# Master Test Suite Runner for Ghost Machines

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "=================================================="
echo "    GHOST MACHINES — MASTER TEST SUITE RUNNER     "
echo "=================================================="
echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "Host OS:   $(uname -s) ($(uname -m))"
echo "Root Dir:  $ROOT_DIR"
echo "=================================================="
echo ""

TEST_SUITES=(
    "$SCRIPT_DIR/test_lint.sh"
    "$SCRIPT_DIR/test_m1_security.sh"
    "$SCRIPT_DIR/test_m2_engine_optimization.sh"
    "$SCRIPT_DIR/test_m3_cli_orchestration.sh"
    "$SCRIPT_DIR/test_m4_snapshot_restore.sh"
    "$SCRIPT_DIR/test_m5_hela_mcp.sh"
    "$SCRIPT_DIR/test_m5_toolchain.sh"
    "$SCRIPT_DIR/test_m6_multi_tenant.sh"
)

TOTAL=${#TEST_SUITES[@]}
PASSED=0
FAILED=0

for SUITE in "${TEST_SUITES[@]}"; do
    SUITE_NAME=$(basename "$SUITE")
    echo ">> Executing: $SUITE_NAME"
    chmod +x "$SUITE"
    if "$SUITE"; then
        echo ">> [PASS] $SUITE_NAME"
        PASSED=$((PASSED + 1))
    else
        echo ">> [FAIL] $SUITE_NAME"
        FAILED=$((FAILED + 1))
    fi
    echo ""
done

echo "=================================================="
echo "               TEST SUMMARY REPORT                "
echo "=================================================="
echo "Total Suites:  $TOTAL"
echo "Passed:        $PASSED"
echo "Failed:        $FAILED"
echo "=================================================="

if [ "$FAILED" -gt 0 ]; then
    echo "Result: FAILED"
    exit 1
else
    echo "Result: ALL TESTS PASSED SUCCESSFULLY! ✓"
    exit 0
fi
