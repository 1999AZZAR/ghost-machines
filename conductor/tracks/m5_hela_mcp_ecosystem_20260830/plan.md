# Implementation Plan: M5 HeLa MCP Ecosystem Integration

## Phase 1: Dockerfile & Build Integration
- [ ] Task: Update `Dockerfile` (Ubuntu) to build HeLa headless-server profile
- [ ] Task: Update `Dockerfile.debian` to build HeLa headless-server profile
- [ ] Task: Update `Dockerfile.alpine` to build HeLa headless-server profile
- [ ] Task: Update `Dockerfile.arch` to build HeLa headless-server profile
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Host Mounting, Compose Config & Verification
- [ ] Task: Update `docker-compose.yml` and `.env.example` with optional local MCP ecosystem mount
- [ ] Task: Create `tests/test_m5_hela_mcp.sh` to validate MCP binary wrappers and ecosystem configurations
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
