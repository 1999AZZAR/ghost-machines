#!/bin/bash
# Test Suite: Static Analysis & Linting

set -e

echo "=================================================="
echo "RUNNING STATIC ANALYSIS & LINTING CHECKS"
echo "=================================================="

# Check 1: Bash Syntax Validation for all shell scripts
echo -n "[LINT 1] Bash syntax check (bash -n) on all .sh scripts... "
SHELL_SCRIPTS=(start.sh clean.sh snapshot.sh restore.sh setup-host.sh aliases.sh entrypoint.sh tenant.sh tests/*.sh)
for SCRIPT in "${SHELL_SCRIPTS[@]}"; do
    if [ -f "$SCRIPT" ]; then
        bash -n "$SCRIPT" || { echo "FAILED: Syntax error in $SCRIPT"; exit 1; }
    fi
done
echo "PASSED (${#SHELL_SCRIPTS[@]} scripts checked)"

# Check 2: ShellCheck (if installed)
echo -n "[LINT 2] ShellCheck static analysis... "
if command -v shellcheck &> /dev/null; then
    for SCRIPT in start.sh clean.sh snapshot.sh restore.sh entrypoint.sh tenant.sh; do
        if [ -f "$SCRIPT" ]; then
            shellcheck -e SC1091 -e SC2034 "$SCRIPT" || { echo "FAILED: ShellCheck warning in $SCRIPT"; exit 1; }
        fi
    done
    echo "PASSED (shellcheck verified)"
else
    echo "SKIPPED (shellcheck not installed, bash -n passed)"
fi

# Check 3: Dockerfile Structural Integrity
echo -n "[LINT 3] Dockerfile structural validation... "
for DOCKERFILE in Dockerfile Dockerfile.debian Dockerfile.alpine Dockerfile.arch; do
    if [ ! -f "$DOCKERFILE" ]; then
        echo "FAILED: $DOCKERFILE does not exist"
        exit 1
    fi
    if ! grep -q "^FROM " "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing FROM instruction"
        exit 1
    fi
    if ! grep -q "ENTRYPOINT" "$DOCKERFILE"; then
        echo "FAILED: $DOCKERFILE missing ENTRYPOINT instruction"
        exit 1
    fi
done
echo "PASSED (4 engines verified)"

# Check 4: Docker Compose Config Validation
echo -n "[LINT 4] Docker Compose syntax and schema validation... "
docker compose config --quiet
echo "PASSED"

echo "=================================================="
echo "ALL STATIC ANALYSIS CHECKS PASSED!"
echo "=================================================="
