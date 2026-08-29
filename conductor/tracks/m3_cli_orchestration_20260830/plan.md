# Implementation Plan: M3 CLI Orchestration & Automation UX

## Phase 1: CLI Flags & Non-Interactive Orchestration [checkpoint: c8d896c]
- [x] Task: Extend `start.sh` CLI flags (`-p/--port`, `-t/--tunnel`, `-b/--build`, trailing compose args) (c8d896c)
- [x] Task: Implement headless flags and confirmation skip in `clean.sh` (c8d896c)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (c8d896c)

## Phase 2: Cross-Distro Host Setup & Shell Utilities [checkpoint: c8d896c]
- [x] Task: Upgrade `setup-host.sh` for multi-distro support (apt, pacman, dnf, zypper, apk) (c8d896c)
- [x] Task: Modernize `aliases.sh` with helper functions (`ghost-status`, `ghost-exec`, `ghost-logs`, `ghost-ssh`) (c8d896c)
- [x] Task: Create `tests/test_m3_cli_orchestration.sh` to validate all CLI scripts and flags (c8d896c)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (c8d896c)
