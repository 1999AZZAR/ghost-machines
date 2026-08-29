# Ghost Machines

Disposable, multi-engine Linux sandboxes and autonomous agent workstations orchestrated via Docker Compose.

Ghost Machines provides reproducible container environments with dynamic host user permissions, non-root execution, accurate resource virtualization through LXCFS, zero-trust remote access, and integration with the HeLa MCP Ecosystem.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Operating System Engines](#operating-system-engines)
- [Deployment Modes & Resource Limits](#deployment-modes--resource-limits)
- [AI Harnesses & HeLa MCP Ecosystem](#ai-harnesses--hela-mcp-ecosystem)
  - [AI Harness Suite](#ai-harness-suite)
  - [HeLa Cellular MCP Stack](#hela-cellular-mcp-stack)
- [Toolchain & Included Packages](#toolchain--included-packages)
- [Security & Access Control](#security--access-control)
- [State Snapshots & Recovery](#state-snapshots--recovery)
- [Cleanup](#cleanup)
- [Task Runner (Makefile) & Shell Shortcuts](#task-runner-makefile--shell-shortcuts)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [License](#license)

---

## Overview

Ghost Machines operates on a semi-immutable architecture:

1. **Immutable Core (Images):** System packages, compilers, developer tools, runtimes, and MCP daemons are built into versioned base images.
2. **Decoupled Mutable State (Mounts):** User home directories and project source code live on host volume mounts under `mounts/`.
3. **Permission Synchronization:** Container processes run under a dedicated `developer` account whose UID and GID mirror your host system, preventing file permission mismatches on shared volumes.

---

## Prerequisites

- **Host Operating System:** Linux, macOS (Docker Desktop / OrbStack), or Windows (WSL2).
- **Architecture:** x86_64 or aarch64 (ARM64).
- **Software:**
  - Docker Engine 20.10 or later.
  - Docker Compose v2.0 or later.
  - Optional: LXCFS on Linux hosts for accurate CPU/memory reporting.

---

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/1999AZZAR/ghost-machines.git
cd ghost-machines
```

### 2. Configure the Host (Optional for Linux)

Run the host setup script to install LXCFS and prepare systemd units:

```bash
make setup-host
# Or directly:
./setup-host.sh
```

### 3. Launch an Environment

Launch interactively:

```bash
make start
# Or directly:
./start.sh
```

Or pass flags directly for non-interactive startup:

```bash
# Launch Ubuntu engine in dual instance mode:
./start.sh -e ubuntu -m dual

# Launch Alpine engine on custom SSH port 2225 with image rebuild:
./start.sh --engine alpine --mode single --port 2225 --build
```

---

## Operating System Engines

Ghost Machines provides four base engines. Each image is configured with identical toolchains, editor setups, and MCP server configurations.

| Engine | Base Image | Package Manager | Intended Use |
| :--- | :--- | :--- | :--- |
| **Ubuntu** | `ubuntu:latest` | `apt-get` | Default development workstation with PPA support. |
| **Debian** | `debian:stable-slim` | `apt-get` | Minimal footprint and stable package base. |
| **Alpine** | `alpine:latest` | `apk` | Lightweight musl-based security sandbox. |
| **Arch Linux** | `archlinux:latest` | `pacman` | Rolling release with current package upstream. |

---

## Deployment Modes & Resource Limits

| Mode | Instances | CPU Limit | RAM Limit | Use Case |
| :--- | :---: | :---: | :---: | :--- |
| **Dual** | 2 | 1.0 core (each) | 8 GB (each) | Isolated multi-node setups and client-server workflows. |
| **Single** | 1 | 1.0 core | 8 GB | Standard standalone sandbox. |
| **Power** | 1 | 2.0 cores | 16 GB | Heavy builds and compute-intensive tasks. |
| **Half-Host** | 1 | 50% Host CPUs | 50% Host RAM | Dynamically scaled to half of host capacity. |

Container names:
- **Dual Mode:** `ghost-machine1`, `ghost-machine2`
- **Single / Power / Half Modes:** `ghost-machine-single`, `ghost-machine-power`, `ghost-machine-half`

---

## AI Harnesses & HeLa MCP Ecosystem

### AI Harness Suite

Each Ghost Machine environment includes three dedicated CLI harnesses alongside the RTK command wrapper:

- **Antigravity CLI** (`agy` / `antigravity`): Agentic automation and multi-step reasoning.
- **OpenCode CLI** (`opencode`): Codebase analysis and autonomous file patching.
- **Kilo CLI** (`kilo` / `kilocode`): Interactive terminal coding assistant.
- **RTK** (`rtk`): Token-optimized terminal execution runner.

### HeLa Cellular MCP Stack

All images build the **HeLa MCP Ecosystem** using the `headless-server` profile (7 core headless servers). System wrapper scripts are linked into `/usr/local/bin`:

| Binary | Server ID | Description |
| :--- | :--- | :--- |
| `mcp-mitosis` | `hela-mitosis` | Dynamic tool discovery, prompt chaining, and sequential reasoning. |
| `mcp-genome` | `hela-genome` | SQLite knowledge graph (`memory.db`), milestone and state tracking. |
| `mcp-membrane` | `hela-membrane` | Sandboxed file system operations, recursive search, and patching. |
| `mcp-nucleus` | `hela-nucleus` | Command runner with timeouts and subshell isolation. |
| `mcp-ribosome` | `hela-ribosome` | Pseudo-terminal (PTY) multiplexer and regex event hooks. |
| `mcp-enzyme` | `hela-enzyme` | Research assistant combining Google Search and cached Wikipedia lookups. |
| `mcp-phenotype` | `hela-phenotype` | UI/UX token generator, OKLCH palettes, and Tailwind utility synthesis. |

Legacy aliases `mcp-terminal` and `mcp-filesystem` are preserved. Client configuration files are automatically generated and pre-configured for all three harnesses:
- **Antigravity CLI:** `~/.mcp/config.json`
- **OpenCode CLI:** `~/.config/opencode/config.json`
- **Kilo CLI:** `~/.config/kilo/config.json`

To mount a local clone of the ecosystem during container development, set `MCP_ECOSYSTEM_LOCAL_PATH` in `.env`:

```bash
MCP_ECOSYSTEM_LOCAL_PATH=/path/to/mcp-ecosystem
```

### Google Conductor Plugin Integration

Google Conductor is built into `/opt/conductor` and globally available across all agent harnesses:

#### Installation Structure

```text
~/.agents/plugins/conductor/           # Permanent Git repository (linked to /opt/conductor)
├── plugin.json
├── rules/
│   └── conductor_antigravity.md       # Native UX & modal dialog rules
└── skills/                            # Live skill definitions, assets & scripts
    ├── conductor-setup
    ├── conductor-new-track
    ├── conductor-implement
    ├── conductor-status
    ├── conductor-revert
    └── conductor-review

~/.agents/skills/                      # Standard Agent SDK Global Skills
├── conductor-setup          -> ~/.agents/plugins/conductor/skills/conductor-setup
├── conductor-new-track      -> ~/.agents/plugins/conductor/skills/conductor-new-track
├── conductor-implement      -> ~/.agents/plugins/conductor/skills/conductor-implement
├── conductor-status         -> ~/.agents/plugins/conductor/skills/conductor-status
├── conductor-revert         -> ~/.agents/plugins/conductor/skills/conductor-revert
└── conductor-review         -> ~/.agents/plugins/conductor/skills/conductor-review

~/.gemini/config/plugins/
└── conductor                -> ~/.agents/plugins/conductor
```

#### Cross-Harness Compatibility

- **Antigravity / Jetski:** Loaded via `~/.gemini/config/plugins/conductor` + `ask_question` GUI modal UX adapter.
- **kilo-cli / OpenCode / Agent SDK:** Discovered automatically from global `~/.agents/skills/`.
- **Live Updates:** Run `git -C ~/.agents/plugins/conductor pull` inside any instance to pull upstream updates immediately.

#### Available Commands

| Command / Trigger | Description |
| :--- | :--- |
| `/conductor:conductor-setup` | Scaffolds project context (`product.md`, `tech-stack.md`, `workflow.md`, styleguides). |
| `/conductor:conductor-new-track` | Initializes a new feature or bug track (`spec.md` + `plan.md`). |
| `/conductor:conductor-implement` | Executes the active track's plan sequentially with TDD validation. |
| `/conductor:conductor-status` | Displays project progress and active tracks. |
| `/conductor:conductor-review` | Code quality review against plan and guidelines. |
| `/conductor:conductor-revert` | Git-aware rollback for logical tracks, phases, or tasks. |

---

## Toolchain & Included Packages

- **Runtimes & Compilers:**
  - **Python:** Astral `uv` / `uvx` for package management, `pipx` for isolated CLI tools, and `python3-venv`.
  - **Rust:** `rustup` minimal profile (`cargo`, `rustc`).
  - **Go:** Go 1.24 toolchain (`/usr/local/go/bin`).
  - **JavaScript:** Node.js 22 LTS, Bun runtime.
  - **C/C++:** `build-essential` / `base-devel`, `cmake`, `make`, `gdb`.
- **Editors & Git:**
  - `helix` (configured with runtime assets), `micro`, `lazygit`, `tmux`.
- **CLI Utilities:**
  - `bat`, `eza`, `zoxide`, `fd-find` (`fd`), `ripgrep` (`rg`), `jq`, `fzf`, `nnn`, `htop`, `btop`, `fastfetch`.

---

## Security & Access Control

1. **Host UID/GID Synchronization:**
   On startup, `start.sh` extracts your host UID and GID and passes them as build arguments. The `developer` account inside the container matches these IDs and receives passwordless `sudo` rights.

2. **SSH Public Key Injection:**
   If a host public key (`~/.ssh/id_rsa.pub`, `~/.ssh/id_ed25519.pub`, etc.) is present, `start.sh` mounts it read-only. On container startup, `entrypoint.sh` installs the key into `.ssh/authorized_keys` with `0700`/`0600` permissions.

3. **Password Authentication:**
   Password authentication defaults to enabled (`root:root`, `developer:developer`). To enforce key-only authentication, set:
   ```bash
   SSH_PASSWORD_AUTH=false
   ```

4. **Cloudflare Zero-Trust Tunnel:**
   To expose the SSH port securely over a Cloudflare Tunnel without opening router ports, configure `TUNNEL_TOKEN` in `.env`.

---

## State Snapshots & Recovery

### Creating a Snapshot

The snapshot tool archives workspace mounts while automatically omitting ephemeral build caches (`node_modules/.cache`, `.npm/_cacache`, `.bun/install/cache`, `target/`, `__pycache__`, `.pytest_cache`, logs):

```bash
make snapshot
# Or with options:
./snapshot.sh -o snapshot_backup.tar.gz

# To capture complete directory without cache exclusions:
./snapshot.sh --all
```

Every snapshot creates two companion files:
- `<snapshot>.sha256`: SHA-256 checksum file.
- `<snapshot>.meta.json`: Metadata manifest containing host architecture, timestamp, file counts, and archive hash.

### Restoring a Snapshot

The restore script validates the SHA-256 checksum, creates an atomic pre-restore backup of existing mounts, and automatically rolls back if archive decompression fails:

```bash
make restore
# Or specify archive directly:
./restore.sh snapshot_backup.tar.gz

# Non-interactive mode (for automated workflows):
./restore.sh --force snapshot_backup.tar.gz
```

---

## Cleanup

Use the cleanup script to remove containers, networks, volumes, and images:

```bash
make clean

# Headless options:
./clean.sh -s          # Stop and remove containers/network (Level 1)
./clean.sh -v          # Stop containers and prune mounts/volumes (Level 2)
./clean.sh -a -y       # Remove containers, volumes, and local images (Level 3)
```

---

## Task Runner (Makefile) & Shell Shortcuts

### Makefile Targets

```text
build-all          Build all 4 OS engine images (Ubuntu, Debian, Alpine, Arch)
build-alpine       Build Alpine Linux template
build-arch         Build Arch Linux template
build-debian       Build Debian Slim template
build-ubuntu       Build Ubuntu master template
clean              Environment cleanup
help               Show available make targets
lint               Run static analysis & ShellCheck verification
restore            Restore workspace snapshot with integrity check
setup-host         Install host system dependencies (LXCFS, Docker)
snapshot           Create snapshot with cache exclusions & SHA-256
start              Launch interactive engine and deployment selector
test               Run automated test suite
```

### Shell Aliases

Source the included alias file to add shortcuts to your shell:

```bash
cat aliases.sh >> ~/.bashrc && source ~/.bashrc
```

- `ghost-status`: Display container status, port mappings, and resource allocations.
- `ghost-exec [container] [command]`: Execute a command in a running instance.
- `ghost-logs [container]`: View real-time container log output.
- `ghost-ssh [1|2|single|power|half]`: Connect directly over SSH.
- `start-ghost`: Open the interactive launcher.

---

## Testing & Quality Assurance

Run the test suite locally:

```bash
make test
```

The test runner validates:
1. `test_lint.sh`: ShellCheck verification, bash syntax check, and Docker compose configuration schema.
2. `test_m1_security.sh`: Host UID/GID sync, non-root user setup, and SSH key permission handling.
3. `test_m2_engine_optimization.sh`: Layer cleanup and multi-engine configuration parity.
4. `test_m3_cli_orchestration.sh`: CLI flag matrices, cleanup workflows, and host helper scripts.
5. `test_m4_snapshot_restore.sh`: Cache exclusions, SHA-256 verification, and atomic rollback recovery.
6. `test_m5_hela_mcp.sh`: HeLa MCP server binaries and isolated AI harness configurations.
7. `test_m5_toolchain.sh`: Python `uv`, `pipx`, and Rust toolchain installations.

All commits and pull requests are validated through GitHub Actions across Linux x86_64 and aarch64 runner matrices.

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
