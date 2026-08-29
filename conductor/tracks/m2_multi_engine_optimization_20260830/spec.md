# Specification: M2 Multi-Engine Parity & Image Optimization

## Overview
This track delivers multi-engine parity across Ubuntu, Debian, Alpine, and Arch Linux, implements aggressive package manager and cache cleanup in all Dockerfiles, standardizes versioning via Build Arguments, and ensures consistent multi-arch binary retrieval.

## Functional Requirements
1. **Engine Parity & Arch Support:**
   - Full support for Arch Linux in CLI flags and interactive prompts.
   - Consistent toolchain availability across all 4 distros (Node.js, Bun, Go, Helix, Micro, Lazygit, Fastfetch, Oh-My-Bash, RTK, MCP servers).
2. **Layer Optimization & Cache Hygiene:**
   - Eliminate leftover package manager indices and archives (`/var/lib/apt/lists/*`, `/var/cache/apk/*`, `/var/cache/pacman/pkg/*`, `/tmp/*`, `/var/tmp/*`).
   - Clean up intermediate archives, tarballs, and build artifacts immediately within each `RUN` layer to maximize Docker layer cache efficiency and reduce final image sizes by 30-50%.
3. **Parametrized Tool Versions:**
   - Define version variables via `ARG` for `GO_VERSION`, `HELIX_VERSION`, and `LAZYGIT_VERSION` to simplify future upgrades.
4. **Automated Verification:**
   - Provide automated test scripts to validate Dockerfile syntax, build arguments, and cleanup directives.

## Acceptance Criteria
- All 4 Dockerfiles adhere to layer optimization rules without persistent package cache bloat.
- Engine selection cleanly routes to `Dockerfile`, `Dockerfile.debian`, `Dockerfile.alpine`, or `Dockerfile.arch`.
- Build args allow overriding Go, Helix, and Lazygit versions.
