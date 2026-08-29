# Implementation Plan: M4 Resilient State & Smart Snapshot Management

## Phase 1: Smart Snapshotting & Checksum Generation [checkpoint: 354d975]
- [x] Task: Upgrade `snapshot.sh` with cache exclusions, custom output flags, and SHA-256 + metadata generation (354d975)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (354d975)

## Phase 2: Atomic Restore & Verification Suite [checkpoint: 354d975]
- [x] Task: Upgrade `restore.sh` with SHA-256 verification, atomic backup & rollback, and non-interactive flags (354d975)
- [x] Task: Create `tests/test_m4_snapshot_restore.sh` to validate backup, checksums, and atomic rollback (354d975)
- [x] Task: Phase Verification & Checkpoint (Refer to workflow.md) (354d975)
