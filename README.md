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
The `start.sh` script is interactive by default but also supports direct CLI arguments:
```bash
chmod +x start.sh
./start.sh [dual|single|power|half]
```

### 4. Zero-Trust Remote Access (Optional)
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

## Technical Specifications

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
- **AI Integrations:** Gemini CLI, OpenAI Codex.
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
