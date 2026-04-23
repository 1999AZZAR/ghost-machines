# Ghost Machines 👻

Master template and orchestration for custom Ubuntu-based development environments. Designed to be lightweight, portable, and powerful.

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/1999AZZAR/ghost-machines.git
   cd ghost-machines
   ```

2. **Build and Start:**
   ```bash
   # This will build the master template and spin up 2 machines
   docker compose up -d --build
   ```

3. **Set up Aliases (Optional but Recommended):**
   Add the helper aliases to your host machine's shell config:
   ```bash
   cat aliases.sh >> ~/.bashrc
   source ~/.bashrc
   ```

---

## 🛠️ Included Tools
The "Master Template" comes pre-installed with:
- **Languages:** Node.js (Latest), Go 1.24, Python 3, Bun
- **IDEs:** Micro, Helix, Lazygit
- **AI:** Gemini CLI, OpenAI Codex
- **System:** htop, nmap, fastfetch, oh-my-bash, alias-hub

---

## ⚙️ Configuration & Portability

### Container Access
- **SSH Port (ubuntu1):** `2223`
- **SSH Port (ubuntu2):** `2224`
- **Default Credentials:** `root:root`

### Persistent Storage
Files inside the containers at `/home/ubuntu` are mapped to the local `./mounts/` directory on your host. This ensures your work persists even if the containers are destroyed.

### Troubleshooting: LXCFS Mounts
This project uses **LXCFS** to provide accurate system information (CPU/RAM) inside the containers.
If you get an error like `bind source path does not exist` for `/var/lib/lxcfs/...`, simply edit `docker-compose.yml` and comment out the following lines under `volumes`:
```yaml
# - /var/lib/lxcfs/proc/cpuinfo:/proc/cpuinfo:ro
# - /var/lib/lxcfs/proc/meminfo:/proc/meminfo:ro
...
```

---

## ⌨️ Connection Aliases
Once set up, use these commands from your host terminal:
- `start-ubuntu`: Enters the first machine.
- `start-ubuntu2`: Enters the second machine.
