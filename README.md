# Ghost Machines

Orchestration and master template for Ubuntu-based development environments. This project provides a standardized, reproducible, and portable environment with automated hardware architecture detection and intelligent resource reporting.

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
The `start.sh` script supports multiple deployment modes:

```bash
chmod +x start.sh

# Deploy 2 instances (1 CPU, 8G RAM each) - Default
./start.sh dual

# Deploy 1 instance (1 CPU, 8G RAM)
./start.sh single

# Deploy 1 instance (2 CPU, 16G RAM)
./start.sh power

# Deploy 1 instance (Half of Host CPU/RAM)
./start.sh half
```

## Technical Specifications

### Deployment Modes
- **Dual:** Orchestrates two separate containers (`ubuntu-container` and `ubuntu2`).
- **Single:** Orchestrates a single container with standard resources.
- **Power:** Orchestrates a single container with doubled CPU and Memory resources.
- **Half-Host:** Dynamically calculates host resources and allocates 50% to a single container.

### Included Software Stack
- **Runtimes:** Node.js, Go 1.24, Python 3, Bun.
- **Development Tools:** Micro, Helix, Lazygit.
- **AI Integrations:** Gemini CLI, OpenAI Codex.
- **System Utilities:** htop, nmap, fastfetch, oh-my-bash, alias-hub.

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
- `start-ubuntu`: Enters the primary instance.
- `start-ubuntu2`: Enters the secondary instance (available in `dual` mode).
