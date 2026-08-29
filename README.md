# Ghost Machines

[![Ghost Machines CI](https://github.com/1999AZZAR/ghost-machines/actions/workflows/ci.yml/badge.svg)](https://github.com/1999AZZAR/ghost-machines/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Architecture: Multi-Arch](https://img.shields.io/badge/Architecture-x86__64%20%7C%20aarch64-brightgreen.svg)](#prerequisites)
[![MCP: HeLa Ecosystem](https://img.shields.io/badge/MCP-HeLa%20Headless%20Server-purple.svg)](#mcp-servers-hela-ecosystem)

High-performance, reproducible development sandboxes and autonomous agent workstations. Powered by Docker Compose, automated host UID/GID synchronization, zero-trust Cloudflare tunnels, LXCFS hardware emulation, the **HeLa MCP Ecosystem** (`headless-server` profile), and isolated AI harnesses.

---

## ⚡ Key Highlights

- **Multi-Engine Parity:** First-class support for **Ubuntu**, **Debian**, **Alpine Linux**, and **Arch Linux**.
- **Host UID/GID Sync & Non-Root Security:** Automatically syncs container user permissions with your host user (`HOST_UID`/`HOST_GID`) to eliminate file permission collisions on workspace mounts.
- **Dedicated AI Harness Suite:** Pre-installed with **`antigravity-cli`** (`agy`), **`opencode-cli`** (`opencode`), and **`kilo-cli`** (`kilo`), coupled with **`rtk`** (Rust Token Killer) for high-efficiency terminal execution.
- **HeLa MCP Ecosystem:** Built-in 7-server headless stack (`mcp-mitosis`, `mcp-genome`, `mcp-membrane`, `mcp-nucleus`, `mcp-ribosome`, `mcp-enzyme`, `mcp-phenotype`) with host mount and pre-generated client configurations.
- **Modern Toolchain:** Python Astral `uv` + `pipx` (PEP 668 compliant), Rust `rustup` minimal profile, Go 1.24, Bun, and Node.js.
- **Smart Snapshots & Atomic Restore:** Bandwidth-efficient backup with cache exclusions, SHA-256 integrity manifests, and fail-safe rollback protection.
- **Unified Task Runner:** Complete `Makefile` workflow runner and automated test suite (`make test`).

---

## 🛠️ Prerequisites

- **Host OS:** Linux (native with optional LXCFS), macOS (Docker Desktop / OrbStack), or Windows (WSL2).
- **Architecture:** `x86_64` (AMD64) or `aarch64` (ARM64).
- **Software:** Docker Engine 20.10+ and Docker Compose v2.0+.

---

## 🚀 Quick Start

### 1. Clone & Configure
```bash
git clone https://github.com/1999AZZAR/ghost-machines.git
cd ghost-machines

# Configure environment variables (optional)
cp .env.example .env
```

### 2. Host Optimization (Linux Hosts)
Install LXCFS for accurate container `/proc` resource reporting:
```bash
make setup-host
# or: ./setup-host.sh
```

### 3. Launch Environment
Launch interactively or pass explicit CLI flags:
```bash
# Interactive menu:
make start

# Headless / Scripted launch (e.g. Ubuntu engine in Dual mode):
./start.sh -e ubuntu -m dual

# Launch Alpine engine on custom SSH port 2225 with forced build:
./start.sh --engine alpine --mode single --port 2225 --build
```

---

## 🎯 OS Engines & Deployment Modes

### Supported Engines
| Engine | Base Image | Package Manager | Focus |
| :--- | :--- | :--- | :--- |
| **Ubuntu** | `ubuntu:latest` | `apt-get` | Feature-rich, broad PPA support, standard workstation. |
| **Debian** | `debian:stable-slim` | `apt-get` | High stability, minimal background overhead. |
| **Alpine** | `alpine:latest` | `apk` | Ultra-lightweight, musl-libc security sandbox. |
| **Arch Linux** | `archlinux:latest` | `pacman` | Bleeding-edge rolling release. |

### Deployment Modes
| Mode | Instances | CPU Limit | RAM Limit | Ideal Workload |
| :--- | :---: | :---: | :---: | :--- |
| **Dual** | 2 | 1.0 (each) | 8G (each) | Distributed pairing, client-server testing. |
| **Single** | 1 | 1.0 | 8G | Focused standalone development. |
| **Power** | 1 | 2.0 | 16G | Intensive compilation, machine learning. |
| **Half-Host** | 1 | 50% Host | 50% Host | Dynamic allocation scaled to host capacity. |

---

## 🧬 HeLa MCP Ecosystem & AI Harnesses

### 1. Isolated AI Harness Suite
Ghost Machines comes pre-configured with strictly isolated AI coding harnesses:
- **Antigravity CLI** (`agy` / `antigravity`): Deep agentic coding and workflow engine.
- **OpenCode CLI** (`opencode`): Autonomous multi-file reasoning harness.
- **Kilo CLI** (`kilo` / `kilocode`): Fast terminal pair programmer.
- **RTK** (`rtk`): Token-optimized bash execution wrapper.

### 2. HeLa MCP Cellular Stack (`headless-server` Profile)
The 7 core headless MCP servers are pre-built, configured, and accessible via `/usr/local/bin/mcp-*`:

| Command | Server ID | Role | Description |
| :--- | :--- | :--- | :--- |
| `mcp-mitosis` | `hela-mitosis` | Orchestration | Dynamic tool routing & sequential thinking reasoning. |
| `mcp-genome` | `hela-genome` | State & Memory | Living SQLite knowledge graph (`memory.db`) & task tracking. |
| `mcp-membrane` | `hela-membrane` | Workspace | Sandboxed file system operations, patch & search. |
| `mcp-nucleus` | `hela-nucleus` | Execution | System interaction, timeouts & RTK token efficiency. |
| `mcp-ribosome` | `hela-ribosome` | PTY Harness | Pseudo-terminal multiplexer & regex event hooks. |
| `mcp-enzyme` | `hela-enzyme` | Research | Unified Google Search & cached Wikipedia fact-checking. |
| `mcp-phenotype` | `hela-phenotype` | UI / Design | Design tokens, OKLCH color palettes & Tailwind synthesis. |

> **Host Development Mount:** To mount your local HeLa MCP repository during development, set `MCP_ECOSYSTEM_LOCAL_PATH=/path/to/mcp-ecosystem` in `.env`.

---

## 📦 Modern Toolchains & Pre-Installed Stack

- **Languages & Runtimes:**
  - **Python:** Astral `uv` / `uvx` (sub-millisecond resolution) + `pipx` (PEP 668 isolated CLIs) + `python3-venv`.
  - **Rust:** `rustup` minimal profile (`cargo`, `rustc`).
  - **Go:** Go 1.24 (`/usr/local/go/bin`).
  - **JavaScript / TypeScript:** Node.js 22 LTS, Bun runtime.
- **Terminal IDEs & Tools:**
  - `helix` (modern modal editor), `micro`, `lazygit`, `tmux`.
  - `bat` (syntax highlighting), `eza` (modern ls), `zoxide` (smart cd), `fd` (fast search), `ripgrep`, `jq`, `fzf`, `nnn`.
- **UI / UX Stack:**
  - `fastfetch`, `oh-my-bash`, `alias-hub`, `neofetch_ascii`.

---

## 🔒 Security & SSH Key Injection

1. **Dynamic Host UID/GID Sync:**
   - Non-root user `developer` (UID/GID matching your host user) is automatically created with passwordless `sudo` privileges.
2. **Automated SSH Key Injection:**
   - Detects your host public key (`~/.ssh/*.pub`) and mounts it to `authorized_keys` with strict `0700`/`0600` permissions.
   - Toggle password authentication off by setting `SSH_PASSWORD_AUTH=false` in `.env`.
3. **Cloudflare Zero-Trust Tunnel:**
   - Connect remotely without opening inbound ports by setting `TUNNEL_TOKEN=<token>` in `.env`.

---

## 💾 Smart State Snapshots & Atomic Restore

### Create Smart Snapshot
Excludes transient build caches (`node_modules/.cache`, `.npm/_cacache`, `.bun/install/cache`, `target/`, `__pycache__`, `.pytest_cache`) to reduce archive sizes by 70–90%:
```bash
make snapshot
# or specify output:
./snapshot.sh -o my_backup.tar.gz

# Include all files without exclusions:
./snapshot.sh --all
```
*Generates companion `my_backup.tar.gz.sha256` and `my_backup.tar.gz.meta.json`.*

### Atomic Restore with Rollback Protection
Verifies SHA-256 integrity, creates a safety backup of existing mounts, and rolls back automatically if extraction fails:
```bash
make restore
# or non-interactive (for CI):
./restore.sh --force my_backup.tar.gz
```

---

## 🧹 Environment Cleanup

```bash
make clean
# Headless flags:
./clean.sh -s          # Stop containers (Level 1)
./clean.sh -v          # Stop containers and remove volumes (Level 2)
./clean.sh -a -y       # Full reset (containers, volumes, and local images)
```

---

## 🧰 Developer Task Runner (`Makefile`)

| Command | Action |
| :--- | :--- |
| `make help` | Display available targets and descriptions. |
| `make test` | Run master automated test suite (7 milestone test suites). |
| `make lint` | Run ShellCheck, bash syntax, and Docker compose validation. |
| `make build-all` | Build all 4 OS engine images (`ubuntu`, `debian`, `alpine`, `arch`). |
| `make start` | Launch environment interactively. |
| `make clean` | Prune and clean environment. |
| `make snapshot` | Create smart state snapshot. |
| `make restore` | Restore workspace state. |
| `make setup-host` | Install host dependencies (LXCFS, Docker). |

---

## 🔗 Shell Aliases

Add helper aliases to your shell:
```bash
cat aliases.sh >> ~/.bashrc && source ~/.bashrc
```
- `ghost-status` — Show container status, ports, and resource limits.
- `ghost-exec [container] [cmd]` — Execute command inside active container.
- `ghost-logs [container]` — Stream logs from container.
- `ghost-ssh [1|2|single|power|half]` — Direct SSH connection to instance.
- `start-ghost` — Interactive launcher.

---

## 🧪 Testing & CI/CD

Run the automated test runner locally:
```bash
make test
```
The test suite validates:
1. `test_lint.sh`: ShellCheck compliance & Dockerfile structure.
2. `test_m1_security.sh`: Host UID/GID sync & SSH permissions.
3. `test_m2_engine_optimization.sh`: Layer cleanup & multi-engine parity.
4. `test_m3_cli_orchestration.sh`: CLI flags & non-interactive UX.
5. `test_m4_snapshot_restore.sh`: Cache exclusions & atomic rollback.
6. `test_m5_hela_mcp.sh`: HeLa MCP suite & AI harness isolation.
7. `test_m5_toolchain.sh`: Python `uv`/`pipx` & Rust toolchain.

---

## 📄 License

MIT © [AZZAR](https://github.com/1999AZZAR)
