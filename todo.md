# Ghost Machines — Master Refinement & Evolution Roadmap

## Strategic Vision
Transform **Ghost Machines** into an enterprise-grade, semi-immutable development environment orchestrator with sub-second lifecycle control, zero permission friction between host and container, multi-distribution parity (Ubuntu, Debian, Alpine, Arch), hardened security, and automated CI/CD validation.

---

## 🎯 Milestone Overview

| Milestone | Target Horizon | Core Objective |
| :--- | :--- | :--- |
| **M1: Security & Identity Hardening** | Phase 1 | Host UID/GID mapping, non-root user option, SSH key injection, secret safety |
| **M2: Multi-Engine & Image Hygiene** | Phase 2 | Arch Linux parity, multi-stage caching, package cleanup, 40%+ size reduction |
| **M3: CLI Orchestration & Automation** | Phase 3 | Non-interactive flags, robust error traps, host-agnostic LXCFS setup |
| **M4: Resilient State & Smart Snapshots** | Phase 4 | Cache-excluded snapshots, SHA256 integrity checks, atomic rollback |
| **M5: Next-Gen Toolchain & MCP Suite** | Phase 5 | `uv` / Python PEP 668 compliance, Rustup minimal, pinned MCP server registry |
| **M6: CI/CD & Test Automation** | Phase 6 | Multi-arch Docker build verification, ShellCheck, Hadolint, smoke test suite |

---

## 📋 Comprehensive Todo & Work Breakdown

### Phase 1: Security Hardening & Host-Container Permission Isolation
> **Goal:** Eliminate `root:root` file ownership conflicts on host mounts and replace default plaintext passwords with secure credential models.

- [ ] **1.1 Host UID/GID Synchronization**
  - [ ] Add `HOST_UID` and `HOST_GID` dynamic detection in `start.sh` (e.g. `id -u`, `id -g`).
  - [ ] Pass `UID`/`GID` as build args or entrypoint user configuration to ensure files created in `mounts/` match host user permissions.
  - [ ] Configure non-root user `developer` / `ubuntu` with passwordless `sudo` rights.
- [ ] **1.2 SSH Authentication & Hardening**
  - [ ] Replace hardcoded `root:root` credentials with dynamic random password generation or SSH public key injection.
  - [ ] Support mounting `~/.ssh/authorized_keys` or `~/.ssh/id_rsa.pub` into container `/home/developer/.ssh/authorized_keys`.
  - [ ] Make `PermitRootLogin` and `PasswordAuthentication` configurable via environment variables (`SSH_PASSWORD_AUTH=false`).
- [ ] **1.3 Secret & Tunnel Hardening**
  - [ ] Ensure `.env` is checked for file permissions (`chmod 600 .env`).
  - [ ] Add pre-flight validation for `TUNNEL_TOKEN` format to avoid launching broken Cloudflare tunnel instances.

---

### Phase 2: Multi-Engine Parity & Image Optimization
> **Goal:** Achieve full feature parity across all 4 OS engines, slim down image layers by 30-50%, and fix engine discovery gaps.

- [ ] **2.1 Arch Linux Engine Integration**
  - [ ] Add Arch Linux as Option 4 in `start.sh` interactive engine selection menu.
  - [ ] Add CLI flag support for Arch (`--engine arch`).
  - [ ] Add `GHOST_IMAGE="arch-template:latest"` and `Dockerfile.arch` mapping in `start.sh`.
- [ ] **2.2 Dockerfile Layer & Cache Cleanup**
  - [ ] **Ubuntu (`Dockerfile`)**: Append `apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*` in single layer.
  - [ ] **Debian (`Dockerfile.debian`)**: Consolidate `apt-get update` & `install`, clean lists.
  - [ ] **Alpine (`Dockerfile.alpine`)**: Remove temporary build deps (`build-base`, temporary archive downloads).
  - [ ] **Arch (`Dockerfile.arch`)**: Clean pacman cache with `pacman -Scc --noconfirm` and remove build artifacts.
- [ ] **2.3 Multi-Stage & Multi-Arch Build Reliability**
  - [ ] Standardize binary download architecture logic (`uname -m` vs Docker `TARGETARCH` / `TARGETOS`).
  - [ ] Add checksum verification for external downloads (Helix, Lazygit, Fastfetch, Go binaries).
  - [ ] Pin software release versions via build arguments (`GO_VERSION`, `HELIX_VERSION`, `LAZYGIT_VERSION`).

---

### Phase 3: CLI Orchestration & Automation UX
> **Goal:** Support fully automated, non-interactive scripting workflows, unified flag parsing, and cross-distro host setup.

- [ ] **3.1 Unified CLI Argument Parsing in `start.sh`**
  - [ ] Implement long/short flag parser:
    - `-e, --engine <ubuntu|debian|alpine|arch>`
    - `-m, --mode <dual|single|power|half>`
    - `-p, --port <base_port>` (default 2223)
    - `-t, --tunnel <token>`
    - `-d, --detach`
    - `-n, --no-build`
    - `-h, --help`
  - [ ] Retain interactive TUI fallback when executed without arguments.
- [ ] **3.2 Headless & Non-Interactive `clean.sh`**
  - [ ] Add CLI arguments: `./clean.sh --stop`, `./clean.sh --volumes`, `./clean.sh --all`, `./clean.sh -y`.
  - [ ] Include container status check before attempting shutdown to avoid redundant errors.
- [ ] **3.3 Cross-Distribution `setup-host.sh`**
  - [ ] Support package managers beyond `apt`:
    - Debian/Ubuntu (`apt-get`)
    - Arch Linux / Manjaro (`pacman`)
    - Fedora / RHEL (`dnf`)
    - Alpine (`apk`)
  - [ ] Fallback gracefully on macOS and non-systemd Linux hosts with informative guidance.
- [ ] **3.4 Ergonomic Shell Aliases & Helper Functions**
  - [ ] Update `aliases.sh` with subcommands:
    - `ghost-exec [container] [cmd]`
    - `ghost-ssh [1|2|single|power|half]`
    - `ghost-status`
    - `ghost-logs`

---

### Phase 4: Resilient State & Smart Snapshot Management
> **Goal:** Make state backup and restore blazing fast, bandwidth-efficient, and fail-safe.

- [ ] **4.1 Cache & Transient Data Exclusion in `snapshot.sh`**
  - [ ] Exclude transient cache directories from tar archives:
    - `node_modules/.cache`
    - `.npm/_cacache`
    - `.bun/install/cache`
    - `target/` (Rust)
    - `.cache/`
    - `__pycache__`
    - `.pytest_cache`
  - [ ] Reduce snapshot archive sizes by up to 90%.
- [ ] **4.2 Snapshot Checksum & Metadata**
  - [ ] Generate companion `.sha256` integrity files for every snapshot.
  - [ ] Embed metadata header (engine, mode, timestamp, host architecture) inside snapshots.
- [ ] **4.3 Atomic & Safe Restore in `restore.sh`**
  - [ ] Implement automatic backup of current `mounts/` to a temporary directory before destructive restore.
  - [ ] Auto-verify SHA256 integrity before unpacking.
  - [ ] Rollback automatically if archive decompression fails.
  - [ ] Support `--force` / `-y` flag for automated CI/CD restores.

---

### Phase 5: Modern Toolchain & MCP Integrations
> **Goal:** Provide modern language utilities, Python PEP 668 compliance, and structured MCP configuration.

- [ ] **5.1 Modern Python Toolchain (`uv` + `pipx`)**
  - [ ] Install `uv` (Astral) for sub-millisecond Python package installs and virtualenv management.
  - [ ] Install `pipx` to manage global CLI applications without `--break-system-packages` violations.
- [ ] **5.2 Rust Toolchain Support (Optional / Lightweight)**
  - [ ] Add `rustup` minimal profile or `cargo-binstall` to allow instant Rust tooling installation inside environments.
- [ ] **5.3 MCP Server Standardization & Config Manager**
  - [ ] Pin GitHub commit SHAs for `terminal-mcp-server` and `filesystem-mcp-server`.
  - [ ] Generate container-level `/root/.mcp/config.json` and `/home/developer/.mcp/config.json` pre-configured with all available servers.
  - [ ] Add test command `mcp-healthcheck` to verify server stdio connectivity.

---

### Phase 6: Quality Assurance, CI/CD & Automated Testing
> **Goal:** Continuous integration pipelines to guarantee 100% build validity across architectures and prevent script regressions.

- [ ] **6.1 Static Analysis & Linting Workflow**
  - [ ] Add `ShellCheck` workflow for all `.sh` scripts with zero tolerance for unbounded variables or unhandled errors.
  - [ ] Add `Hadolint` validation for all 4 Dockerfiles.
  - [ ] Add `Yamllint` / `docker compose config` validation.
- [ ] **6.2 Automated Smoke Test Suite (`tests/`)**
  - [ ] `tests/test_scripts_syntax.sh`: Validate exit codes and help flags.
  - [ ] `tests/test_docker_builds.sh`: Build test images for Ubuntu, Debian, Alpine, Arch.
  - [ ] `tests/test_snapshot_restore.sh`: End-to-end test of snapshot creation, checksum verification, and atomic restore.
- [ ] **6.3 GitHub Actions Multi-Arch CI Matrix**
  - [ ] Set up GitHub Actions workflow testing on `ubuntu-latest` (x86_64) and `ubuntu-24.04-arm` (aarch64).
  - [ ] Automated release packaging on version tags.
- [ ] **6.4 Unified Makefile / Developer Task Runner**
  - [ ] Provide simple shortcuts:
    - `make up`, `make down`, `make clean`
    - `make snapshot`, `make restore`
    - `make lint`, `make test`

---

## 📈 Tracking & Execution Protocol
- Every phase follows Conductor TDD and Git checkpointing (`conductor/workflow.md`).
- Updates to tech stack or dependencies must be updated in `conductor/tech-stack.md`.
- Tasks marked `[x]` upon verified test completion and Git note attachment.
