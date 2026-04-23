# Ghost Machines

Orchestration and master template for Ubuntu-based development environments. This project provides a standardized, reproducible, and portable environment with automated hardware architecture detection and intelligent resource reporting.

## Prerequisites

### Operating Systems
- **Linux:** Native support with optional LXCFS integration.
- **macOS:** Supported via Docker Desktop.
- **Windows:** Supported via WSL2 (Windows Subsystem for Linux).

### Requirements
- **Hardware:** x86_64 or aarch64 (ARM64) architecture.
- **Software:** Docker Engine 20.10+ and Docker Compose v2.0+.
- **Connectivity:** Port 2223 and 2224 must be available on the host for SSH access.

## Deployment

### 1. Repository Initialization
Clone the repository to your host machine:
```bash
git clone https://github.com/1999AZZAR/ghost-machines.git
cd ghost-machines
```

### 2. Host Configuration (Optional)
On Linux hosts, install LXCFS to allow containers to accurately report host CPU and Memory resources via `/proc`:
```bash
chmod +x setup-host.sh
./setup-host.sh
```

### 3. Environment Lifecycle
Use the provided `start.sh` script to initialize the environment. This script automatically detects the presence of LXCFS and configures volume mounts accordingly:
```bash
chmod +x start.sh
./start.sh
```

## Technical Specifications

### Machine Specifications (Per Instance)
By default, each ghost machine is configured with the following resource limits:
- **CPU:** 1.0 Core (Dedicated via `cpuset`).
- **Memory:** 8 GB RAM.
- **Storage:** Shared host storage via volume mounts.
- **Operating System:** Ubuntu 24.04 LTS (Latest).

### Included Software Stack
- **Runtimes:** Node.js (Latest), Go 1.24, Python 3, Bun.
- **Development Tools:** Micro, Helix, Lazygit.
- **AI Integrations:** Gemini CLI, OpenAI Codex.
- **System Utilities:** htop, nmap, fastfetch, oh-my-bash, alias-hub.

### Container Architecture
The environments are built from a unified `Dockerfile` that performs architecture detection at build-time. This ensures that binaries for Go, Helix, and Lazygit are compatible with the host CPU (x86_64 or aarch64).

### Network Configuration
- **ubuntu-container:** SSH access via host port `2223`.
- **ubuntu2:** SSH access via host port `2224`.
- **Network Driver:** Bridge (Internal name: `ghost_sandbox`).

### Resource Persistence
User data within the containers is persisted to the host filesystem via volume mapping:
- `/home/ubuntu` (container) -> `./mounts/ubuntu1/` (host)
- `/home/ubuntu` (container) -> `./mounts/ubuntu2/` (host)

## Security and Access

### Credentials
- **Default Username:** root
- **Default Password:** root

### Hardening
The default configuration allows root login over SSH for ease of use in sandbox environments. For deployment in production or untrusted networks:
1. Modify the `root` password in the `Dockerfile`.
2. Update `sshd_config` to disable password authentication in favor of SSH keys.

## Host Integration

### Connection Aliases
To streamline access to the environments, source the `aliases.sh` file in your shell configuration (`.bashrc` or `.zshrc`):
```bash
cat aliases.sh >> ~/.bashrc
source ~/.bashrc
```
**Available Commands:**
- `start-ubuntu`: Enters the primary container.
- `start-ubuntu2`: Enters the secondary container.

## Troubleshooting

### LXCFS Mount Errors
If the `start.sh` script fails to correctly detect LXCFS or if the host paths for `/var/lib/lxcfs/proc` are restricted, manually disable these mounts in `docker-compose.yml` by commenting out the `/proc/` volume lines.

### Binary Incompatibility
If a tool fails to execute with an "Exec format error", ensure the `docker-compose.yml` `build` context was used correctly to trigger an architecture-specific build for your current host.
