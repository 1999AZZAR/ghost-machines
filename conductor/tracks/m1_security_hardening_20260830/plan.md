# Implementation Plan: M1 Security Hardening

## Phase 1: Host UID/GID Synchronization & User Setup [checkpoint: 25684a5]
- [x] Task: Update `start.sh` with dynamic host UID/GID detection and `.env` permission check (25684a5)
- [x] Task: Update `docker-compose.yml` with UID/GID build arguments and SSH key mount support (25684a5)
- [x] Task: Update Dockerfiles (Ubuntu, Debian, Alpine, Arch) with non-root developer user & sudoers setup (25684a5)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (25684a5)

## Phase 2: SSH Hardening, Key Injection & Environment Validation [checkpoint: 25684a5]
- [x] Task: Implement SSH authorized_keys injection and conditional password auth in Docker entrypoint / sshd config (25684a5)
- [x] Task: Add pre-flight TUNNEL_TOKEN format check and .env.example parameter documentation (25684a5)
- [x] Task: Write automated test script to verify UID/GID mapping and SSH configuration (25684a5)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (25684a5)
