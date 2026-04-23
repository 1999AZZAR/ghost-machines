# Ghost Machines

Orchestration and master template for Ubuntu-based development environments.

## Deployment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/1999AZZAR/ghost-machines.git
   cd ghost-machines
   ```

2. **Configure Host (Optional - for LXCFS):**
   Run the setup script to install and configure LXCFS on the host machine:
   ```bash
   chmod +x setup-host.sh
   ./setup-host.sh
   ```

3. **Build and initialize:**
   ```bash
   docker compose up -d --build
   ```

4. **Configure shell aliases:**
   Append connection helpers to the host shell configuration:
   ```bash
   cat aliases.sh >> ~/.bashrc
   source ~/.bashrc
   ```

## Included Software
- **Runtimes:** Node.js, Go 1.24, Python 3, Bun
- **Editors:** Micro, Helix, Lazygit
- **Tooling:** Gemini CLI, OpenAI Codex, htop, nmap, fastfetch, oh-my-bash, alias-hub

## Configuration

### Network and Access
- **ubuntu1 SSH Port:** 2223
- **ubuntu2 SSH Port:** 2224
- **Root Password:** root

### Persistence
The containers map host-local directories to the internal user environment:
- `./mounts/ubuntu1` -> `/home/ubuntu`
- `./mounts/ubuntu2` -> `/home/ubuntu`

### Hardware Architecture
The Dockerfile detects the host architecture (x86_64 or aarch64) during the build phase to install compatible binaries for Go, Helix, and Lazygit.

### LXCFS Integration
This configuration assumes the presence of LXCFS on the host for accurate resource reporting within `/proc`. If the host does not have LXCFS installed, comment out the following volume definitions in `docker-compose.yml`:
- `/var/lib/lxcfs/proc/cpuinfo`
- `/var/lib/lxcfs/proc/meminfo`
- `/var/lib/lxcfs/proc/stat`
- `/var/lib/lxcfs/proc/swaps`
- `/var/lib/lxcfs/proc/uptime`

## Operation
Use the following commands from the host terminal to access the environments:
- `start-ubuntu`: Initialize session in the first instance.
- `start-ubuntu2`: Initialize session in the second instance.
