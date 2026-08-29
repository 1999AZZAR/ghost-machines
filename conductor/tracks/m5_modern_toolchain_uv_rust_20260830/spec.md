# Specification: M5 Modern Python (uv/pipx) & Rust Toolchains

## Overview
This track equips all Ghost Machines images with a modern, high-performance Python toolchain (`uv` and `pipx`) for PEP 668 compliance and lightning-fast package resolution, as well as a minimal Rust toolchain (`rustup`, `cargo`, `rustc`) for systems programming and fast binary builds.

## Functional Requirements
1. **Modern Python Toolchain:**
   - Install `uv` and `uvx` (Astral) globally in `/usr/local/bin/`.
   - Install `pipx` across all 4 OS distributions.
2. **Rust Toolchain:**
   - Install `rustup` with `--profile minimal` (cargo + rustc) without bloated documentation layers.
   - Symlink or export cargo binaries in global PATH for both `root` and `${GHOST_USER}`.
3. **Automated Verification:**
   - Create `tests/test_m5_toolchain.sh` to test `uv`, `pipx`, and `rustup` directives across all Dockerfiles and compose configs.

## Acceptance Criteria
- All 4 Dockerfiles configure `uv`, `pipx`, and `rustup`.
- Binaries are available in system PATH.
