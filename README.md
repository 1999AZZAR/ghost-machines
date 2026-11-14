# Ghost Machines

Disposable, multi-engine Linux sandboxes and autonomous agent workstations orchestrated via Docker Compose.

Ghost Machines provides reproducible container environments with dynamic host user permissions, non-root execution, accurate resource virtualization through LXCFS, zero-trust remote access, and integration with the HeLa MCP Ecosystem.

![Ghost Machines Architecture](assets/ghost-machines-architecture.png)

[![Demo](https://asciinema.org/a/sDNJP7aYOabLz0k6.svg)](https://asciinema.org/a/sDNJP7aYOabLz0k6)

---

## Table of Contents

- [Overview](#overview)
- [Infrastructure as Code (IaC) Architecture](#infrastructure-as-code-iac-architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Image Sources: Prebuilt vs Local Build](#image-sources-prebuilt-vs-local-build)
- [Lifecycle: Start, Stop, Restart, Remove](#lifecycle-start-stop-restart-remove)
- [Connecting to a Sandbox](#connecting-to-a-sandbox)
- [Operating System Engines](#operating-system-engines)
- [Deployment Modes & Resource Limits](#deployment-modes--resource-limits)
- [Multi-Tenant Workspace-as-a-Service (WaaS)](#multi-tenant-workspace-as-a-service-waas)
- [AI Harnesses & HeLa MCP Ecosystem](#ai-harnesses--hela-mcp-ecosystem)
- [Toolchain & Included Packages](#toolchain--included-packages)
- [Security & Access Control](#security--access-control)
- [UI/UX & Shell Stack](#uiux--shell-stack)
- [State Snapshots & Recovery](#state-snapshots--recovery)
- [Cleanup](#cleanup)
- [Task Runner (Makefile) & Shell Shortcuts](#task-runner-makefile--shell-shortcuts)
- [Troubleshooting](#troubleshooting)
- [Testing & Quality Assurance](#testing--quality-assurance)
- [License](#license)

---

## Overview

Ghost Machines provides disposable, multi-engine Linux sandboxes and autonomous agent workstations orchestrated via Docker Compose.

> **Ghost vs regular VM?** See [docs/comparison-vs-vm.md](docs/comparison-vs-vm.md) — pros/cons, overhead, and decision matrix.

---

## Infrastructure as Code (IaC) Architecture

Ghost Machines is a practical implementation of **[Infrastructure as Code (IaC)](https://learn.microsoft.com/en-us/devops/deliver/what-is-infrastructure-as-code)** for development workstations and autonomous AI agent execution environments:

1. **Declarative Definitions:** Entire environments (OS kernels, runtimes, modern compilers, MCP daemons, user security, and network topology) are defined strictly in version-controlled code (`docker-compose.yml`, multi-engine Dockerfiles, and orchestration scripts).
2. **Idempotent & Automated Provisioning:** Any developer or CI pipeline can provision an identical, production-ready workstation with a single command (`./start.sh` or `make start`), eliminating configuration drift and "works on my machine" inconsistencies.
3. **Semi-Immutable Separation of Concerns:**
   - **Immutable Core (Images):** System packages, compilers, developer tools, runtimes, and MCP daemons are compiled into versioned, reproducible base images.
   - **Decoupled Mutable State (Mounts):** User home directories, project source code, and working files reside on host volume mounts under `mounts/`.
4. **Dynamic Permission Synchronization:** Container processes run under a dedicated `developer` account whose UID and GID dynamically match the host system, ensuring seamless read/write access to shared volumes without permission collisions.
5. **State Traceability & Disaster Recovery:** Smart snapshot management (`snapshot.sh` / `restore.sh`) with companion SHA-256 verification and atomic rollbacks allows instantaneous point-in-time recovery.

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

Three decisions, one command. **Engine** = Linux flavour, **mode** = how many machines, **image source** = prebuilt download or local build.

### 1. Clone

```bash
git clone https://github.com/1999AZZAR/ghost-machines.git
cd ghost-machines
```

### 2. Prepare the host (Linux only, once)

Installs LXCFS so `htop`/`free` inside the sandbox report the container's limits instead of the host totals. Skipped automatically on macOS and WSL.

```bash
make setup-host      # or ./setup-host.sh
```

### 3. Pick an image source

| | **Prebuilt (GHCR)** | **Local build** |
| :--- | :--- | :--- |
| First run | ~1 minute (pull) | 5–15 minutes (build) |
| Size | 1.2–1.6 GB per engine | same, plus build cache |
| Needs repo Dockerfiles | No | Yes |
| Updates | `--pull` / `--build` | rebuild |
| Best for | trying it, production, CI | editing the image, custom packages |

**Prebuilt** — one package per engine, published on `v*` tags:

```bash
./start.sh --prebuilt ubuntu -m single
```

**Local build** — compiles the Dockerfile in this repo:

```bash
./start.sh -e ubuntu -m single --build
```

Full details, tags and how to mix both: [Image Sources: Prebuilt vs Local Build](#image-sources-prebuilt-vs-local-build).

### 4. Start

```bash
./start.sh                                  # interactive: asks engine + mode
./start.sh --prebuilt ubuntu -m single      # 1 machine, 8 GB / 1 CPU
./start.sh -e debian -m dual --build        # 2 machines, built locally
./start.sh -e alpine -m power -p 2225       # heavy profile on a custom port
```

`start.sh` syncs your host UID/GID, wires your SSH key, and prints the image it is using (`[IMAGE] … GHCR prebuilt` vs `local build`) before starting.

### 5. Connect

```bash
ssh -p 2223 developer@localhost
```

| Mode | Container | Host port | Connect with |
| :--- | :--- | :---: | :--- |
| **Dual** (1st) | `ghost-machine1` | `2223` | `ssh -p 2223 developer@localhost` |
| **Dual** (2nd) | `ghost-machine2` | `2224` | `ssh -p 2224 developer@localhost` |
| **Single** | `ghost-machine-single` | `2223` | `ssh -p 2223 developer@localhost` |
| **Power** | `ghost-machine-power` | `2223` | `ssh -p 2223 developer@localhost` |
| **Half** | `ghost-machine-half` | `2223` | `ssh -p 2223 developer@localhost` |

- **User:** `developer` · **Password:** `ghost` · **sudo:** `ghost`
- **Root:** `ssh -p 2223 root@localhost` (password `ghost`)
- **Key auth:** if `~/.ssh/id_ed25519.pub` / `~/.ssh/id_rsa.pub` exists on the host it is mounted and authorized automatically — no password needed.
- **No SSH at all:** `docker exec -it ghost-machine-single bash`

Lost track of the port or the container name? `./start.sh status` prints them:

```text
NAME                   IMAGE                                              STATUS          PORTS
ghost-machine-single   ghcr.io/1999azzar/ghost-machine-ubuntu:latest      Up 2 minutes    0.0.0.0:2223->22/tcp

SSH endpoints:
  ghost-machine-single     ssh -p 2223 developer@localhost
```

More connection options (app ports, VS Code, Cloudflare Tunnel, host-key warnings): [Connecting to a Sandbox](#connecting-to-a-sandbox).

### 6. Stop, resume, or remove

```bash
./start.sh status     # what is running, which image, which SSH port
./start.sh stop       # remove containers + network — images, mounts/ and config stay
./start.sh restart    # restart existing containers in place
./start.sh logs       # follow the container log (entrypoint output, errors)
./clean.sh -a -y      # also drop images (Level 3) — see Cleanup
```

Your work lives in `mounts/`, not in the container, so `stop`, `clean.sh`, even a full image rebuild leave it intact. Full matrix: [Lifecycle: Start, Stop, Restart, Remove](#lifecycle-start-stop-restart-remove).

---

## Image Sources: Prebuilt vs Local Build

Every start uses exactly one image. `start.sh` resolves it in this order:

1. `--image <ref>` (explicit)
2. `--prebuilt [engine]` → `ghcr.io/1999azzar/ghost-machine-<engine>:latest`
3. `GHOST_IMAGE` from your environment or `.env`
4. Otherwise the local build tag for the engine: `ubuntu-template:latest`, `debian-template:latest`, `alpine-template:latest`, `arch-template:latest`

If the resolved reference contains a `/` it is treated as a registry image: it is **pulled** instead of built, and `--build` is ignored with a notice.

### Prebuilt images (GHCR)

Published by `.github/workflows/publish.yml` on release tags (`v*`) and on manual dispatch, multi-arch (`linux/amd64`, `linux/arm64`):

| Engine | Reference | Approx. size |
| :--- | :--- | :--- |
| Ubuntu | `ghcr.io/1999azzar/ghost-machine-ubuntu:latest` | ~1.38 GB amd64 / 1.21 GB arm64 |
| Debian | `ghcr.io/1999azzar/ghost-machine-debian:latest` | ~1.36 GB / 1.20 GB |
| Alpine | `ghcr.io/1999azzar/ghost-machine-alpine:latest` | ~1.59 GB / 1.32 GB |
| Arch | `ghcr.io/1999azzar/ghost-machine-arch:latest` | ~1.63 GB both |

Tags in each package: `latest`, the release tag (e.g. `v2.1.0`), and `latest-<short-sha>`.

```bash
# pull automatically if missing
./start.sh --prebuilt debian -m single

# or pull explicitly, then start
docker pull ghcr.io/1999azzar/ghost-machine-debian:latest
./start.sh --image ghcr.io/1999azzar/ghost-machine-debian:latest -m single

# refresh a prebuilt image you already have
./start.sh --prebuilt debian -m single --pull

# make it the default without repeating the flag
echo 'GHOST_IMAGE=ghcr.io/1999azzar/ghost-machine-ubuntu:latest' >> .env
./start.sh -e ubuntu -m single
```

Prebuilt images also provision the toolchain and harness CLIs at build time; `harness-update` keeps opencode/agy/rtk current at runtime, so an older image tag is not a version freeze.

### Local build

```bash
# build + start in one step
./start.sh -e ubuntu -m single --build

# build only (no containers), usable later without --build
make build-ubuntu        # Dockerfile        -> ubuntu-template:latest
make build-debian        # Dockerfile.debian -> debian-template:latest
make build-alpine        # Dockerfile.alpine -> alpine-template:latest
make build-arch          # Dockerfile.arch   -> arch-template:latest
make build-all           # all four

# start from the local tag you just built
./start.sh -e ubuntu -m single
```

If the local tag is missing and `--build` is not passed, Docker Compose builds it automatically, so the first `./start.sh` on a clean machine builds once and later runs reuse the image.

Prebuilt images are built with `HOST_UID=1000` / `HOST_GID=1000`; the entrypoint re-syncs the `developer` account to your host IDs at start, so mounts still match your user.

### Which one am I running right now?

```bash
./start.sh status                                          # STATUS table prints the IMAGE column
docker inspect -f '{{.Config.Image}}' ghost-machine-single  # exact reference the container uses
docker images | grep -E 'ghost-machine|template'           # what exists locally
```

`start.sh` also announces it on every launch: `[IMAGE] ghcr.io/… (GHCR prebuilt, no local build)` vs `[IMAGE] ubuntu-template:latest (local build from Dockerfile)`. A `ghcr.io/…` reference means you are on a pulled image; a `*-template:latest` tag means a local build.

---

## Lifecycle: Start, Stop, Restart, Remove

`./start.sh` is the lifecycle entry point. The plain Docker Compose commands are listed too, in case you prefer them — they behave identically.

| Goal | Command | Keeps |
| :--- | :--- | :--- |
| Start / (re)create containers | `./start.sh [flags]` | `mounts/`, images, `.env` |
| Show state, image, SSH port | `./start.sh status` | — |
| Restart in place (no recreate) | `./start.sh restart` | everything |
| Pause (container kept, process stopped) | `docker compose --profile dual stop` | container, everything |
| Resume a pause | `docker compose --profile dual start` | container, everything |
| Stop and delete containers + network | `./start.sh stop` | `mounts/`, images, `.env` |
| Delete containers + volumes | `./clean.sh -v -y` | `mounts/`, images |
| Delete everything incl. images | `./clean.sh -a -y` | `mounts/` |
| Wipe images **and** work | `./clean.sh --nuke --hard -y` | nothing |
| Container log | `./start.sh logs` / `docker logs -f <name>` | — |
| Shell without SSH | `docker exec -it ghost-machine-single bash` | — |
| Refresh harness binaries | `./start.sh --update-harness` | — |

Makefile shortcuts: `make stop`, `make status`, `make logs`, `make restart`, `make prebuilt ENGINE=debian MODE=single`.

Notes:

- **Only ports are re-created.** `./start.sh` reuses the existing image; add `--build` (local tag) or `--pull` (registry tag) to get a new one.
- **Work survives everything except `--hard`.** Home directory = `mounts/ubuntu1`, `mounts/ubuntu2`, or `mounts/tenants/<id>`, bind-mounted from the host repo.
- **Changing `.env` needs a recreate.** `./start.sh` alone updates most settings, but ports, tunnel token and image are applied on container creation: `./start.sh stop && ./start.sh …`.
- **Tenants have their own lifecycle:** `./tenant.sh start|stop|restart <id>` (see [Multi-Tenant WaaS](#multi-tenant-workspace-as-a-service-waas)).

---

## Connecting to a Sandbox

### SSH (default path)

```bash
ssh -p 2223 developer@localhost      # password: ghost
ssh -p 2223 root@localhost           # password: ghost
```

If host keys change between recreations (normal — each new container gets a new SSH host key), the client refuses with `Host key verification failed`. Clear the stale entry:

```bash
ssh-keygen -R "[localhost]:2223"
```

or use the helper that skips the check:

```bash
source aliases.sh
ghost-ssh single        # developer@localhost:G1_PORT
ghost-ssh 2             # second machine in dual mode
```

### Editor / IDE

Any tool that speaks SSH works. VS Code: **Remote-SSH → Connect to Host → `ssh -p 2223 developer@localhost`**. JetBrains Gateway, Zed remote, `rsync`, `scp -P 2223`, and `sftp -P 2223` use the same host/port/user.

### Reaching a web/app server inside the sandbox

Only port 22 is published to the host. Forward anything else over SSH instead of editing compose:

```bash
# inside the sandbox: vite --port 3000 / uvicorn --port 8000 / whatever
ssh -p 2223 -L 3000:localhost:3000 developer@localhost
# now browse http://localhost:3000 on your host
```

### Remote access over the internet (Cloudflare Tunnel)

```bash
# .env
TUNNEL_TOKEN=eyJ...
./start.sh --prebuilt ubuntu -m single
```

`start.sh` enables the `remote` compose profile and runs `cloudflared`. Point a public hostname at the service (`ssh://ghost1:22`) in the Cloudflare dashboard, then from your laptop:

```bash
cloudflared access ssh --hostname ghost.example.com
# and in ~/.ssh/config:
# Host ghost
#   HostName ghost.example.com
#   ProxyCommand cloudflared access ssh --hostname %h
#   User developer
```

No router ports are opened; access is gated by Cloudflare Access policies.

### Keeping access working

- `SSH_PASSWORD_AUTH=false` disables password login — make sure a host key is authorized first (`~/.ssh/*.pub`), otherwise you lock yourself out until you set it back to `true` and recreate with `./start.sh stop && ./start.sh …`.
- The `developer` account has passwordless-shell sudo with password `ghost`; for anything stronger, replace it (`passwd`, `usermod -L root`) inside the sandbox after connecting.

---

---

## Operating System Engines

Ghost Machines provides four base engines. Each image is configured with identical toolchains, editor setups, and MCP server configurations — they differ only in the base distro and package manager.

| Engine | Base Image | Package Manager | Flag | Intended Use |
| :--- | :--- | :--- | :--- | :--- |
| **Ubuntu** | `ubuntu:latest` | `apt-get` | `-e ubuntu` | Default development workstation with PPA support. |
| **Debian** | `debian:stable-slim` | `apt-get` | `-e debian` | Minimal footprint and stable package base. |
| **Alpine** | `alpine:latest` | `apk` | `-e alpine` | Lightweight musl-based security sandbox. |
| **Arch Linux** | `archlinux:latest` | `pacman` | `-e arch` | Rolling release with current package upstream. |

Either source works for every engine — prebuilt (`./start.sh --prebuilt debian -m single`) or local build (`./start.sh -e debian -m single --build`). See [Image Sources](#image-sources-prebuilt-vs-local-build).

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

### Real-World Resource Benchmarks

Ghost Machines is engineered for near-zero idle overhead with high performance under load:

| Operational State | Workload / Active Processes | CPU Usage | Memory Usage | Memory % (8 GB Sandbox) | Active PIDs |
| :--- | :--- | :---: | :---: | :---: | :---: |
| **Idle / Stale** | Container standby (`sshd` waiting for connections) | `0.00%` | `~73.5 MiB` | `0.90%` | `1` |
| **Active AI Agent** | `opencode` active session + all 7 HeLa MCP server daemons | `~1.99%` | `~1,002 MiB` | `12.23%` | `65` |

> [!TIP]
> Under full autonomous load with all 7 background MCP daemons actively communicating, the workstation consumes only **~1 GB**, leaving **~88% of memory headroom (~7 GB)** dedicated to heavy compilers (Rust, Go, Node, C++), test suites, and project builds.

---

## Multi-Tenant Workspace-as-a-Service (WaaS)

Ghost Machines implements a multi-tenant **[Workspace as a Service (WaaS)](https://en.wikipedia.org/wiki/Workspace_as_a_service)** and **[Cloud Development Environment (CDE)](https://learn.microsoft.com/en-us/azure/dev-box/overview-what-is-microsoft-dev-box)** architecture via `tenant.sh`. It enables engineering teams, educators, organizations, and VPS hosts to dynamically provision, scale, monitor, and vend isolated developer and autonomous AI agent workstations on a single high-performance machine:

### Quick Tenant Management Commands

**A. Using prebuilt images (fast, no build) — one per engine:**

Debian:
```bash
docker pull ghcr.io/1999azzar/ghost-machine-debian:latest
./tenant.sh add alice --engine debian --cpu 2.0 --mem 4G --port 2225
```
Ubuntu:
```bash
docker pull ghcr.io/1999azzar/ghost-machine-ubuntu:latest
./tenant.sh add bob --engine ubuntu --cpu 4.0 --mem 8G
```
Alpine:
```bash
docker pull ghcr.io/1999azzar/ghost-machine-alpine:latest
./tenant.sh add carol --engine alpine --port 2227
```
Arch:
```bash
docker pull ghcr.io/1999azzar/ghost-machine-arch:latest
./tenant.sh add dave --engine arch --port 2228
```

**B. Building locally (from Dockerfile):**

Debian (build):
```bash
./tenant.sh add alice --engine debian --build --cpu 2.0 --mem 4G --port 2225
```
Arch (build):
```bash
./tenant.sh add bob --engine arch --build --cpu 4.0 --mem 8G
```

**Common operations:**

```bash
# List all active tenants, engines, allocated ports, and storage size:
./tenant.sh list

# Real-time resource metrics across all tenant containers:
./tenant.sh stats

# Snapshot or restore an individual tenant's workspace:
./tenant.sh snapshot alice
./tenant.sh restore alice snapshots/snapshot_alice_20260830.tar.gz

# Delete a tenant with safe container teardown:
./tenant.sh delete bob -y
```

### Multi-Tenant Architecture & Isolation Guarantees

1. **Storage Isolation**: Each tenant's persistent workspace resides strictly in `./mounts/tenants/<tenant_id>/`. Non-overlapping volume mounts prevent cross-tenant data leakage.
2. **Resource Quotas**: Hard cgroup memory limits (e.g. `4G`), CPU quotas (e.g. `2.0`), and PID limits prevent noisy-neighbor performance degradation.
3. **Dedicated Endpoints**: Each workspace runs on its own SSH port or Cloudflare Tunnel endpoint with independent credentials and keys.
4. **Independent Lifecycle & Disaster Recovery**: Start, stop, restart, backup, and restore individual tenant workstations without disrupting other active users.

---

## AI Harnesses & HeLa MCP Ecosystem

### AI Harness Suite & RTK Token Optimization

Each Ghost Machine environment includes two dedicated CLI harnesses alongside the RTK token optimization runner:

- **[Antigravity CLI](https://github.com/google-antigravity/antigravity-cli)** (`agy` / `antigravity`): Agentic automation and multi-step reasoning.
- **[OpenCode v2](https://github.com/anomalyco/opencode)** (`opencode`): Codebase analysis and autonomous file patching.
- **[RTK](https://github.com/rtk-ai/rtk)** (`rtk`): Token-optimized terminal execution runner.

#### Versioning: Always Latest, Never Pinned

No harness version is baked into the images. A single in-image helper, `harness-update`, resolves each tool from its official upstream source and installs the result into `/usr/local/bin`:

| Harness | Source |
| :--- | :--- |
| `opencode` | `https://opencode.ai/v2/install` |
| `agy` | `https://antigravity.google/cli/install.sh` |
| `rtk` | `https://github.com/rtk-ai/rtk/releases/latest/download` |

It runs at three points:

1. **Image build** — every rebuild pulls the current upstream release.
2. **Container start** — the entrypoint refreshes stale binaries (default once per 24h, cached by a stamp file).
3. **On demand** — `./start.sh --update-harness`, or inside a sandbox:

```bash
harness-update                 # refresh everything now
harness-update opencode        # refresh one harness
harness-update --if-due        # refresh only when the stamp is stale
harness-update --interval 6    # change the 24h staleness window
```

| Variable | Default | Purpose |
| :--- | :--- | :--- |
| `GHOST_HARNESS_UPDATE` | `latest` | `latest` (refresh when stale), `always` (every start), `off` (never). |
| `HARNESS_UPDATE_INTERVAL_HOURS` | `24` | Staleness window used by `latest`. |

A host `agy` binary is still exposed read-only at `/usr/local/bin/agy-host`; when present it wins, otherwise the refreshed in-image build is used.

#### RTK Universal Auto-Rewrite Hook

Every sandbox environment comes pre-configured with a universal `PreToolUse` hook (`~/.config/rtk/rtk-rewrite.sh`, `~/.gemini/config/hooks.json`, `~/.claude/settings.json`). Whenever an AI harness executes a terminal command (e.g. `git status`, `cargo test`, `pytest`), the hook automatically intercepts the raw command and proxies it through RTK, reducing LLM token consumption by **60%–90%** with zero manual configuration required.


### HeLa Cellular MCP Stack

All images build the **[HeLa MCP Ecosystem](https://github.com/1999AZZAR/hela-mcp-ecosystem)** using the `headless-server` profile (7 core headless servers). System wrapper scripts are linked into `/usr/local/bin`:

| Binary | Server ID | Description |
| :--- | :--- | :--- |
| `mcp-mitosis` | `hela-mitosis` | Dynamic tool discovery, prompt chaining, and sequential reasoning. |
| `mcp-genome` | `hela-genome` | SQLite knowledge graph (`memory.db`), milestone and state tracking. |
| `mcp-membrane` | `hela-membrane` | Sandboxed file system operations, recursive search, and patching. |
| `mcp-nucleus` | `hela-nucleus` | Command runner with timeouts and subshell isolation. |
| `mcp-ribosome` | `hela-ribosome` | Pseudo-terminal (PTY) multiplexer and regex event hooks. |
| `mcp-enzyme` | `hela-enzyme` | Research assistant combining Google Search and cached Wikipedia lookups. |
| `mcp-phenotype` | `hela-phenotype` | UI/UX token generator, OKLCH palettes, and Tailwind utility synthesis. |

Client configuration files are automatically generated and pre-configured for both AI harnesses:
- **Antigravity CLI:** `~/.mcp/config.json`
- **OpenCode v2:** `~/.config/opencode/opencode.json`

To mount a local clone of the ecosystem during container development, set `MCP_ECOSYSTEM_LOCAL_PATH` in `.env`:

```bash
MCP_ECOSYSTEM_LOCAL_PATH=/path/to/mcp-ecosystem
```

### Google Conductor Plugin Integration

**[Google Conductor](https://github.com/gemini-cli-extensions/conductor)** is built into `/opt/conductor` and globally available across all agent harnesses:

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
- **OpenCode / Agent SDK:** Discovered automatically from global `~/.agents/skills/`.
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
  - **Python:** Astral [`uv`](https://github.com/astral-sh/uv) / `uvx` for package management, `pipx` for isolated CLI tools, and `python3-venv`.
  - **Rust:** [`rustup`](https://github.com/rust-lang/rustup) minimal profile (`cargo`, `rustc`).
  - **Go:** Go 1.24 toolchain (`/usr/local/go/bin`).
  - **JavaScript:** Node.js 22 LTS, [Bun](https://github.com/oven-sh/bun) runtime.
  - **C/C++:** `build-essential` / `base-devel`, `cmake`, `make`, `gdb`.
- **Editors & Git:**
  - [`helix`](https://github.com/helix-editor/helix) (configured with runtime assets), `micro`, [`lazygit`](https://github.com/jesseduffield/lazygit), `tmux`.
- **CLI Utilities:**
  - `bat`, `eza`, `zoxide`, `fd-find` (`fd`), `ripgrep` (`rg`), `jq`, `fzf`, `nnn`, `htop`, `btop`, [`fastfetch`](https://github.com/fastfetch-cli/fastfetch), `figlet`.

---

## Security & Access Control

1. **Default Credentials & Architecture as Code:**
   - Default User: `developer` (UID/GID auto-synced with host).
   - Default Password: `ghost` (for both `developer` and `root`).
   - Sudo Privileges: Standard sudo enabled for `developer` (enter `ghost` when prompted).

2. **Host UID/GID Synchronization:**
   On startup, `start.sh` extracts your host UID and GID and passes them as build/runtime parameters. The `developer` account inside the container matches these IDs, eliminating permission collisions on shared volume mounts.

3. **SSH Public Key Injection:**
   If a host public key (`~/.ssh/id_ed25519.pub`, `~/.ssh/id_rsa.pub`, etc.) is present, `start.sh` mounts it read-only. On container startup, `entrypoint.sh` installs the key into `.ssh/authorized_keys` with strict `0700`/`0600` permissions.

4. **Password Authentication:**
   Password authentication defaults to enabled (`developer:ghost`). To enforce key-only authentication, set in `.env`:
   ```bash
   SSH_PASSWORD_AUTH=false
   ```

5. **Cloudflare Zero-Trust Tunnel:**
   To expose the SSH port securely over a Cloudflare Tunnel without opening router ports, configure `TUNNEL_TOKEN` in `.env`.

---

## UI/UX & Shell Stack

Every Ghost Machine container automatically initializes a full developer shell environment out-of-the-box:

- **[Oh-My-Bash](https://github.com/ohmybash/oh-my-bash):** Pre-configured with themes, Git prompt, and directory helpers.
- **[Alias-Hub](https://github.com/1999AZZAR/alias-hub):** Categorized command aliases auto-loaded from `~/alias-hub` (including `cls` for clear, navigation, git, system tools).
- **[Fastfetch](https://github.com/fastfetch-cli/fastfetch) + [Neofetch-ASCII](https://github.com/1999AZZAR/neofetch_ascii):** Custom fastfetch configuration (`~/.config/fastfetch/config.jsonc`) with `fetch`, `rfetch` (random ASCII banner), and `ascii` (slideshow/banner via `figlet`).



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
./clean.sh -s          # Level 1 — stop containers/network
./clean.sh -v          # Level 2 — above + volumes
./clean.sh -a -y       # Level 3 — above + local *-template images
./clean.sh --nuke -y   # Level 4 — Level 3 + GHCR prebuilts + builder cache
./clean.sh --nuke --hard -y  # Level 4 hard — also wipe mounts/ (true 1st-user nuke)
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

## Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Bind for 0.0.0.0:2223 failed: port is already allocated` | another container/process holds the port | start on another port: `./start.sh … -p 2225` (dual mode uses `2225` and `2226`), or `./start.sh stop` first |
| `ssh: connect to host localhost port 2223: Connection refused` | container not running, still initializing, or a different port | `./start.sh status`, then `./start.sh logs` if it is starting |
| `Permission denied (publickey,password)` | `SSH_PASSWORD_AUTH=false` and no authorized key | set `SSH_PASSWORD_AUTH=true` in `.env`, `./start.sh stop && ./start.sh …`; or add your pubkey to `~/.ssh/authorized_keys` |
| `Host key verification failed` | new container = new SSH host key | `ssh-keygen -R "[localhost]:2223"` or `ghost-ssh` |
| `Permission denied` writing in `~/` (mounted project) | container UID ≠ host UID | re-run `./start.sh` (re-syncs `HOST_UID`/`HOST_GID`); last resort `sudo chown -R "$(id -u):$(id -g)" mounts/` |
| `--build` appears to do nothing | image reference is a registry tag | use the local tag (`-e ubuntu` without `GHOST_IMAGE`) or drop `GHOST_IMAGE` from `.env` |
| Image unexpectedly rebuilt on first run | no local image and no prebuilt pulled | expected: Compose builds the missing tag. Use `--prebuilt` to avoid the build |
| `denied` / `401` pulling from GHCR | private/renamed package or anonymous rate limit | `echo $GH_TOKEN \| docker login ghcr.io -u <user> --password-stdin` |
| `htop`/`free` show host RAM | LXCFS not installed (or disabled) | `make setup-host` on Linux; on macOS/WSL this is expected (`--no-lxcfs`) |
| `permission denied /var/run/docker.sock` | user not in `docker` group | `sudo usermod -aG docker $USER` then re-login |
| Harness CLI missing or stale inside the sandbox | build-time download failed (offline) | `harness-update` inside the sandbox, or `./start.sh --update-harness`, or wait for the entrypoint refresh and check `docker exec <name> cat /var/log/ghost-harness-update.log` |
| Container restarts in a loop | entrypoint or sshd config error | `./start.sh logs`; fix, then `./start.sh stop && ./start.sh …` |
| Need to start over completely | accumulated images/volumes | `./clean.sh --nuke -y` (keeps `mounts/`), add `--hard` to wipe work too |

Still stuck? `./start.sh status`, `./start.sh logs`, and `docker compose --profile dual config` (resolved compose file with your variables) answer most of it.

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
