# Specification: M4 Resilient State & Smart Snapshot Management

## Overview
This track transforms state backup and restoration in Ghost Machines into a bandwidth-efficient, verified, and fail-safe operation by excluding ephemeral cache folders, generating SHA-256 checksums and metadata, and implementing atomic rollback during restore.

## Functional Requirements
1. **Smart Cache Exclusion in `snapshot.sh`:**
   - Exclude build caches, dependency caches, and transient files by default:
     - `node_modules/.cache`
     - `.npm/_cacache`
     - `.bun/install/cache`
     - `target/` (Cargo)
     - `.cache/`
     - `__pycache__`
     - `.pytest_cache`
     - `*.tmp`, `*.log`, `.DS_Store`
   - Support `--all` to include all files without exclusions.
   - Support `-o, --output <filename>` to specify target archive name.
2. **Integrity Checksums & Metadata:**
   - Automatically generate companion `<snapshot_name>.sha256` integrity files.
   - Generate `<snapshot_name>.meta.json` with host details, timestamp, file counts, and archive hash.
3. **Atomic & Safe Restore in `restore.sh`:**
   - Verify SHA-256 integrity if `.sha256` companion file exists.
   - Automatically back up existing `mounts/` to a temporary directory (`mounts_backup_<timestamp>`).
   - If unpacking fails, automatically roll back from backup without data loss.
   - Support non-interactive `-y, --yes, --force` flags for automation / CI.
4. **Automated Verification:**
   - Create `tests/test_m4_snapshot_restore.sh` validating end-to-end backup, exclusion, checksum generation, verification, and atomic rollback.

## Acceptance Criteria
- Snapshot archive sizes are reduced by 70-90% by stripping transient caches.
- Restoring corrupt archives is safely rejected and previous state is preserved.
- Non-interactive restore functions reliably.
