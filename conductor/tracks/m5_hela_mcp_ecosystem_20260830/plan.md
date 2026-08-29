# Implementation Plan: M5 HeLa MCP Ecosystem Integration

## Phase 1: Dockerfile & Build Integration [checkpoint: a54a22a]
- [x] Task: Update `Dockerfile` (Ubuntu) to build HeLa headless-server profile (a54a22a)
- [x] Task: Update `Dockerfile.debian` to build HeLa headless-server profile (a54a22a)
- [x] Task: Update `Dockerfile.alpine` to build HeLa headless-server profile (a54a22a)
- [x] Task: Update `Dockerfile.arch` to build HeLa headless-server profile (a54a22a)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (a54a22a)

## Phase 2: Host Mounting, Compose Config & Verification [checkpoint: a54a22a]
- [x] Task: Update `docker-compose.yml` and `.env.example` with optional local MCP ecosystem mount (a54a22a)
- [x] Task: Create `tests/test_m5_hela_mcp.sh` to validate MCP binary wrappers and ecosystem configurations (a54a22a)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (a54a22a)
