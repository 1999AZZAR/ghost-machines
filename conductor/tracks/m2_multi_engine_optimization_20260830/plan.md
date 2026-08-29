# Implementation Plan: M2 Multi-Engine Parity & Image Optimization

## Phase 1: Dockerfile Layer Hygiene & Version Parametrization [checkpoint: 7d986b4]
- [x] Task: Update `Dockerfile` (Ubuntu) with build args and layer cleanup (7d986b4)
- [x] Task: Update `Dockerfile.debian` with build args and layer cleanup (7d986b4)
- [x] Task: Update `Dockerfile.alpine` with build args and layer cleanup (7d986b4)
- [x] Task: Update `Dockerfile.arch` with build args and layer cleanup (7d986b4)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (7d986b4)

## Phase 2: Engine CLI Routing & Optimization Verification [checkpoint: 7d986b4]
- [x] Task: Update `start.sh` CLI parser for `-e / --engine` (ubuntu, debian, alpine, arch) (7d986b4)
- [x] Task: Create `tests/test_m2_engine_optimization.sh` to test cleanup rules and build args (7d986b4)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (7d986b4)
