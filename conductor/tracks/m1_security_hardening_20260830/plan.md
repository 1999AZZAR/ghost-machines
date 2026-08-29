# Implementation Plan: M1 Security Hardening

## Phase 1: Host UID/GID Synchronization & User Setup
- [ ] Task: Update `start.sh` with dynamic host UID/GID detection and `.env` permission check
- [ ] Task: Update `docker-compose.yml` with UID/GID build arguments and SSH key mount support
- [ ] Task: Update Dockerfiles (Ubuntu, Debian, Alpine, Arch) with non-root developer user & sudoers setup
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: SSH Hardening, Key Injection & Environment Validation
- [ ] Task: Implement SSH authorized_keys injection and conditional password auth in Docker entrypoint / sshd config
- [ ] Task: Add pre-flight TUNNEL_TOKEN format check and .env.example parameter documentation
- [ ] Task: Write automated test script to verify UID/GID mapping and SSH configuration
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
