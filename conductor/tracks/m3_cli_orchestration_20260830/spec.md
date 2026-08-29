# Specification: M3 CLI Orchestration & Automation UX

## Overview
This track refines and unifies the developer CLI interface, enabling completely headless scripting, non-interactive CI/CD runs, cross-distribution host setup (Ubuntu/Debian, Arch, Fedora, Alpine), and rich helper shell utilities.

## Functional Requirements
1. **Extended Flags in `start.sh`:**
   - `-p, --port <port>` (base SSH port override)
   - `-t, --tunnel <token>` (explicit tunnel token override)
   - `-d, --detach` (run in background, default)
   - `-b, --build` (force rebuild images before starting)
2. **Headless & Flag-Driven `clean.sh`:**
   - `--stop` (Level 1: stop and remove containers/networks)
   - `--volumes` / `--deep` (Level 2: remove volumes)
   - `--all` / `--reset` (Level 3: remove volumes and image)
   - `-y, --yes, --force` (skip interactive prompt for automation)
3. **Cross-Distro `setup-host.sh`:**
   - Auto-detect package manager: `apt-get`, `pacman`, `dnf`, `zypper`, `apk`.
   - Install `lxcfs` appropriately for each distro.
   - Detect systemd vs non-systemd init systems with clear fallback diagnostics.
4. **Enhanced Helper Aliases (`aliases.sh`):**
   - Provide command functions: `ghost-exec`, `ghost-ssh`, `ghost-status`, `ghost-logs`.
   - Maintain backwards-compatibility with `start-ghost`, `start-ghost1`, `start-ghost2`.
5. **Automated Verification:**
   - Create `tests/test_m3_cli_orchestration.sh` to test all flags and scripts.

## Acceptance Criteria
- All CLI utilities can be executed without interactive prompts when flags are provided.
- `setup-host.sh` works on non-Debian host distros.
- Shell aliases are valid POSIX/Bash syntax and provide helpful status commands.
