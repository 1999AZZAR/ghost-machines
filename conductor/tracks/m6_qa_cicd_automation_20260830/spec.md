# Specification: M6 Quality Assurance, CI/CD & Automated Testing

## Overview
This track delivers a continuous integration pipeline, static analysis validation, comprehensive test automation runner, and a unified task-runner `Makefile` for Ghost Machines.

## Functional Requirements
1. **Master Test Runner (`tests/run_all.sh`):**
   - Discovers and executes all test suites (`test_m1_security.sh`, `test_m2_engine_optimization.sh`, `test_m3_cli_orchestration.sh`, `test_m4_snapshot_restore.sh`, `test_m5_hela_mcp.sh`, `test_m5_toolchain.sh`).
   - Produces a clear test report with passing/failing tallies and clean exit codes.
2. **Static Analysis & Linting (`tests/test_lint.sh`):**
   - Validates Shell scripts with ShellCheck or bash `-n` syntax checking.
   - Validates Dockerfile syntax and instruction ordering.
   - Validates `docker compose config` against schema.
3. **GitHub Actions Multi-Arch CI Matrix (`.github/workflows/ci.yml`):**
   - Triggers on `push` and `pull_request` to `main`/`master`.
   - Matrix of linting, test runner, and Docker engine smoke tests.
4. **Unified Makefile (`Makefile`):**
   - Standard targets: `help`, `test`, `lint`, `build-ubuntu`, `build-debian`, `build-alpine`, `build-arch`, `build-all`, `clean`, `snapshot`, `restore`.

## Acceptance Criteria
- Running `make test` executes all test suites and passes with 0 errors.
- Running `make lint` validates shell scripts, dockerfiles, and compose configurations.
- GitHub Actions workflow is syntactically valid and ready for remote CI.
