# Implementation Plan: M2 Multi-Engine Parity & Image Optimization

## Phase 1: Dockerfile Layer Hygiene & Version Parametrization
- [ ] Task: Update `Dockerfile` (Ubuntu) with build args and layer cleanup
- [ ] Task: Update `Dockerfile.debian` with build args and layer cleanup
- [ ] Task: Update `Dockerfile.alpine` with build args and layer cleanup
- [ ] Task: Update `Dockerfile.arch` with build args and layer cleanup
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Engine CLI Routing & Optimization Verification
- [ ] Task: Update `start.sh` CLI parser for `-e / --engine` (ubuntu, debian, alpine, arch)
- [ ] Task: Create `tests/test_m2_engine_optimization.sh` to test cleanup rules and build args
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
