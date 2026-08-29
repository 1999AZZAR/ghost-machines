# Implementation Plan: M4 Resilient State & Smart Snapshot Management

## Phase 1: Smart Snapshotting & Checksum Generation
- [ ] Task: Upgrade `snapshot.sh` with cache exclusions, custom output flags, and SHA-256 + metadata generation
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)

## Phase 2: Atomic Restore & Verification Suite
- [ ] Task: Upgrade `restore.sh` with SHA-256 verification, atomic backup & rollback, and non-interactive flags
- [ ] Task: Create `tests/test_m4_snapshot_restore.sh` to validate backup, checksums, and atomic rollback
- [ ] Task: Phase Verification & Checkpoint (Refer to workflow.md)
