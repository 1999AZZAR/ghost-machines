# Ghost Machines

Orchestration and master template for Ubuntu-based development environments. This project provides a standardized, reproducible, and portable environment with automated hardware architecture detection, intelligent resource reporting, and optional zero-trust remote access.

## Prerequisites

### Operating Systems
- **Linux:** Native support with optional LXCFS integration.
- **macOS:** Supported via Docker Desktop.
- **Windows:** Supported via WSL2.

### Requirements
- **Hardware:** x86_64 or aarch64 (ARM64) architecture.
- **Software:** Docker Engine 20.10+ and Docker Compose v2.0+.

## Deployment

### 1. Repository Initialization
```bash
git clone https://github.com/1999AZZAR/ghost-machines.git
cd ghost-machines
```

### 2. Host Configuration (Optional)
On Linux hosts, install LXCFS for accurate resource reporting:
```bash
chmod +x setup-host.sh
./setup-host.sh
```

### 3. Initialize Environments
The `start.sh` script provides interactive selection for the **Engine** (Ubuntu or Debian) and the **Deployment Mode**:

```bash
chmod +x start.sh
./start.sh
```

**Engines:**
- **Ubuntu:** Standard, feature-rich base.
- **Debian:** Slim, lightweight, and high-stability base.
- **Alpine:** Ultra-lightweight, minimal security-focused base.

### 4. Configuration (Optional)
The project supports `.env` files for managing environment variables. Copy the example template to get started:
```bash
cp .env.example .env
# Edit .env to add your TUNNEL_TOKEN or customize ports
```

### 5. Zero-Trust Remote Access (Optional)
To enable secure remote access via Cloudflare Tunnel without opening host ports, export your tunnel token before starting:
```bash
export TUNNEL_TOKEN="your_cloudflare_tunnel_token"
./start.sh
```

## Maintenance Utilities

### Backup and Restore
Archive and recover your workspace state across physical machines:
- **Snapshot:** `./snapshot.sh` (Creates a `.tar.gz` of the `mounts/` directory)
- **Restore:** `./restore.sh <snapshot_file.tar.gz>`

### Environment Cleanup
Use the `clean.sh` utility to stop and prune environments:
```bash
chmod +x clean.sh
./clean.sh
```

## Key Advantages: Semi-Immutable Architecture

This project implements a **Semi-Immutable Architecture**, following the "Cattle, Not Pets" philosophy for development environments.

### 1. Immutable Core (The Image)
The entire toolchain, OS configuration, and runtime environment are defined as a read-only Docker image. This ensures environmental consistency across different physical hosts and prevents "configuration drift" over time.

### 2. Decoupled Mutable State (The Mounts)
User data and project code are isolated in persistent volume mounts. By separating the **Environment** (Immutable) from the **Data** (Mutable), the ghost machines become entirely disposable. 

### 3. Rapid Recovery and Security
- **Predictability:** Eliminates the "it works on my machine" problem by standardizing the build process.
- **Resilience:** If an environment becomes unstable, it can be destroyed and redeployed in seconds without data loss.
- **Security:** Every restart reverts the system writable layer to a verified, known-good state defined in the codebase.

## Technical Specifications

### Architecture and Efficiency
The Ghost Machine framework utilizes a layered, copy-on-write (CoW) filesystem architecture to minimize resource consumption during scaling.

| Engine | Base Image | Compressed Size | Characteristics |
| :--- | :--- | :--- | :--- |
| **Ubuntu** | `ubuntu:latest` | ~4.69 GB | Feature-rich, broad PPA support, standard dev experience. |
| **Debian** | `debian:stable-slim` | ~4.68 GB | Lightweight, high stability, minimal background overhead. |
| **Alpine** | `alpine:latest` | TBD | Ultra-lightweight, minimal security-focused base. |

- **Marginal Disk Cost:** < 1 MB per additional instance. Since all instances share the read-only base layers of their respective engine, new machines only consume space for unique writable data.
- **Memory Scaling:** While disk space is shared, RAM is allocated per instance. Each machine is restricted to the defined memory limits (default: 8 GB) but only consumes what is actively required by running processes.

### Deployment Modes
| Mode | Instances | CPU Limit | RAM Limit | Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Dual** | 2 | 1.0 (each) | 8G (each) | Standard distributed development. |
| **Single** | 1 | 1.0 | 8G | Minimal resource footprint. |
| **Power** | 1 | 2.0 | 16G | High-performance computing tasks. |
| **Half-Host** | 1 | 50% Host | 50% Host | Dynamic scaling based on host power. |

### Naming Conventions
Containers are named dynamically based on the active mode:
- **Dual:** `ghost-machine1`, `ghost-machine2`
- **Single/Power/Half:** `ghost-machine-single`, `ghost-machine-power`, `ghost-machine-half`

### Included Software Stack
- **Runtimes:** Node.js, Go 1.24, Python 3, Bun.
- **Editors:** Micro, Helix, Lazygit.
- **Utilities:** nnn (File Manager), fzf (Fuzzy Finder), ripgrep (Search), tmux (Multiplexer).
- **Modern CLI:** bat (cat with syntax), eza (better ls), zoxide (smarter cd), fd (faster find), jq (json processor).
- **AI Integrations:** Gemini CLI, OpenAI Codex, RTK (Rust Token Killer).
- **MCP Servers:** Terminal, Filesystem, and Sequential Thinking (pre-installed in `/root/MCPservers`).
- **Monitoring:** btop, htop, nmap, fastfetch, oh-my-bash, alias-hub.

## Security and Access

### Credentials
- **Default Username:** root
- **Default Password:** root

### Hardening
The default configuration allows root login over SSH. For non-sandbox environments:
1. Modify the `root` password in the `Dockerfile`.
2. Update `sshd_config` to disable password authentication.

## Host Integration

### Connection Aliases
Add helper aliases to your shell configuration:
```bash
cat aliases.sh >> ~/.bashrc
source ~/.bashrc
```
**Commands:**
- `start-ghost`: Enters the active instance (any mode).
- `start-ghost1`: Enters `ghost-machine1` (available in `dual` mode).
- `start-ghost2`: Enters `ghost-machine2` (available in `dual` mode).
