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

- [x] **1.1 Host UID/GID Synchronization**
  - [x] Add `HOST_UID` and `HOST_GID` dynamic detection in `start.sh` (e.g. `id -u`, `id -g`).
  - [x] Pass `UID`/`GID` as build args or entrypoint user configuration to ensure files created in `mounts/` match host user permissions.
  - [x] Configure non-root user `developer` / `ubuntu` with passwordless `sudo` rights.
- [x] **1.2 SSH Authentication & Hardening**
  - [x] Replace hardcoded `root:root` credentials with dynamic random password generation or SSH public key injection.
  - [x] Support mounting `~/.ssh/authorized_keys` or `~/.ssh/id_rsa.pub` into container `/home/developer/.ssh/authorized_keys`.
  - [x] Make `PermitRootLogin` and `PasswordAuthentication` configurable via environment variables (`SSH_PASSWORD_AUTH=false`).
- [x] **1.3 Secret & Tunnel Hardening**
  - [x] Ensure `.env` is checked for file permissions (`chmod 600 .env`).
  - [x] Add pre-flight validation for `TUNNEL_TOKEN` format to avoid launching broken Cloudflare tunnel instances.

---

### Phase 2: Multi-Engine Parity & Image Optimization
> **Goal:** Achieve full feature parity across all 4 OS engines, slim down image layers by 30-50%, and fix engine discovery gaps.

- [x] **2.1 Arch Linux Engine Integration**
  - [x] Add Arch Linux as Option 4 in `start.sh` interactive engine selection menu.
  - [x] Add CLI flag support for Arch (`--engine arch`).
  - [x] Add `GHOST_IMAGE="arch-template:latest"` and `Dockerfile.arch` mapping in `start.sh`.
- [x] **2.2 Dockerfile Layer & Cache Cleanup**
  - [x] **Ubuntu (`Dockerfile`)**: Append `apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*` in single layer.
  - [x] **Debian (`Dockerfile.debian`)**: Consolidate `apt-get update` & `install`, clean lists.
  - [x] **Alpine (`Dockerfile.alpine`)**: Remove temporary build deps (`build-base`, temporary archive downloads).
  - [x] **Arch (`Dockerfile.arch`)**: Clean pacman cache with `pacman -Scc --noconfirm` and remove build artifacts.
- [x] **2.3 Multi-Stage & Multi-Arch Build Reliability**
  - [x] Standardize binary download architecture logic (`uname -m` vs Docker `TARGETARCH` / `TARGETOS`).
  - [x] Add checksum verification for external downloads (Helix, Lazygit, Fastfetch, Go binaries).
  - [x] Pin software release versions via build arguments (`GO_VERSION`, `HELIX_VERSION`, `LAZYGIT_VERSION`).

---

### Phase 3: CLI Orchestration & Automation UX
> **Goal:** Support fully automated, non-interactive scripting workflows, unified flag parsing, and cross-distro host setup.

- [x] **3.1 Unified CLI Argument Parsing in `start.sh`**
  - [x] Implement long/short flag parser:
    - `-e, --engine <ubuntu|debian|alpine|arch>`
    - `-m, --mode <dual|single|power|half>`
    - `-p, --port <base_port>` (default 2223)
    - `-t, --tunnel <token>`
    - `-d, --detach`
    - `-b, --build`
    - `-h, --help`
  - [x] Retain interactive TUI fallback when executed without arguments.
- [x] **3.2 Headless & Non-Interactive `clean.sh`**
  - [x] Add CLI arguments: `./clean.sh --stop`, `./clean.sh --volumes`, `./clean.sh --all`, `./clean.sh -y`.
  - [x] Include container status check before attempting shutdown to avoid redundant errors.
- [x] **3.3 Cross-Distribution `setup-host.sh`**
  - [x] Support package managers beyond `apt`:
    - Debian/Ubuntu (`apt-get`)
    - Arch Linux / Manjaro (`pacman`)
    - Fedora / RHEL (`dnf`)
    - Alpine (`apk`)
    - openSUSE (`zypper`)
  - [x] Fallback gracefully on macOS and non-systemd Linux hosts with informative guidance.
- [x] **3.4 Ergonomic Shell Aliases & Helper Functions**
  - [x] Update `aliases.sh` with subcommands:
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

- [x] **5.1 HeLa MCP Ecosystem Integration (`headless-server` profile)**
  - [x] Integrate `hela-mcp-ecosystem` (7 Core Headless servers: Mitosis, Genome, Membrane, Nucleus, Ribosome, Enzyme, Phenotype).
  - [x] Support host directory mount (`/home/azzar/project/MCPservers/mcp-ecosystem` -> `/opt/mcp-ecosystem-local`).
  - [x] Expose global binary wrappers (`mcp-mitosis`, `mcp-genome`, `mcp-membrane`, `mcp-nucleus`, `mcp-ribosome`, `mcp-enzyme`, `mcp-phenotype`).
- [ ] **5.2 Modern Python Toolchain (`uv` + `pipx`)**
  - [ ] Install `uv` (Astral) for sub-millisecond Python package installs and virtualenv management.
  - [ ] Install `pipx` to manage global CLI applications without `--break-system-packages` violations.
- [ ] **5.3 Rust Toolchain Support (Optional / Lightweight)**
  - [ ] Add `rustup` minimal profile or `cargo-binstall` to allow instant Rust tooling installation inside environments.

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
