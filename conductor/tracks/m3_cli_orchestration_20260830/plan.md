# Implementation Plan: M3 CLI Orchestration & Automation UX

## Phase 1: CLI Flags & Non-Interactive Orchestration
- [ ] Task: Extend `start.sh` CLI flags (`-p/--port`, `-t/--tunnel`, `-b/--build`, trailing compose args)
- [ ] Task: Implement headless flags and confirmation skip in `clean.sh`
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Cross-Distro Host Setup & Shell Utilities
- [ ] Task: Upgrade `setup-host.sh` for multi-distro support (apt, pacman, dnf, zypper, apk)
- [ ] Task: Modernize `aliases.sh` with helper functions (`ghost-status`, `ghost-exec`, `ghost-logs`, `ghost-ssh`)
- [ ] Task: Create `tests/test_m3_cli_orchestration.sh` to validate all CLI scripts and flags
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
