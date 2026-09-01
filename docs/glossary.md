# Glossary — Ghost Machines

Comprehensive, beginner-friendly definitions for every term you’ll meet.

| Term | What It Means | Why It Matters Here |
|---|---|---|
| **Ghost Machines** | The project itself — a toolkit for disposable Linux sandboxes. | The “hotel” we’re describing. |
| **Ghost / Sandbox / Workstation** | A running container you code inside. Thrown away when done. | Your private room. |
| **Container** | A sealed Linux room that shares the host’s kernel (foundation) but has its own walls (filesystem, processes). Created by Docker. | Boots in 1–2s, ~73 MB idle. Not a VM. |
| **VM (Virtual Machine)** | A full computer inside your computer (own kernel, hypervisor). Can run Windows/BSD. Slow, heavy, strongly isolated. | For hostile code, kernel work. Ghost is not a VM. |
| **Docker / Docker Compose** | The engine and blueprint language for containers. `docker-compose.yml` describes what to run. | How Ghost is defined and started (`docker compose up`). |
| **Image** | A read-only template (like a hotel room blueprint). Built from a `Dockerfile`. | Ghost images are `ubuntu-template:latest`, etc. or GHCR prebuilts. |
| **Dockerfile** | Recipe that builds an image (installs tools, copies files). | Ghost has 4: `Dockerfile` (ubuntu), `.debian`, `.alpine`, `.arch`. |
| **GHCR** | GitHub Container Registry (`ghcr.io`) — a shelf of ready-made images. | Pull `ghost-machine-ubuntu:latest` instead of building for 10 min. |
| **Multi-arch** | One tag contains two images: `linux/amd64` (Intel/AMD) + `linux/arm64` (Apple Silicon/ARM VPS). Docker auto-picks. | Works on any laptop or VPS. |
| **Engine** | Choice of Linux base (Ubuntu/Debian/Alpine/Arch). Same toolchain, different base. | Pick one based on PPA vs slim vs musl vs rolling. |
| **Mode** | Resource profile (`dual/single/power/half`) that sets `deploy.resources.limits` + container names. | Scale from 1c/8G to 50% of host. |
| **IaC (Infrastructure as Code)** | Defining machines in code (Dockerfile/compose) so anyone can reproduce them. | Ghost is IaC — no “works on my machine”. |
| **Mount / Volume** | Host folder mapped into the container (`mounts/`). Your work stays after container deletion. | Your files live here — not inside the throw-away image. |
| **UID/GID Sync** | Aligning container user `developer` to your host `id -u/g` so files aren’t owned by root. | Fixes “permission denied” hell. |
| **LXCFS** | A helper that makes `free/htop` inside the container show cgroup limits, not host totals. | Only on Linux; macOS/WSL auto-skip. |
| **Non-root User** | Running as `developer`, not `root`. Safer, with `sudo` via `ghost`. | Security best practice. |
| **SSH** | Remote shell (`ssh -p 2223 developer@localhost`). Pass `ghost` or key `~/.ssh/id_ed25519.pub`. | How you connect to the room. |
| **WaaS (Workspace as a Service)** | Vending isolated workspaces to many users on one server. | `tenant.sh` — one host, many students. |
| **CDE (Cloud Development Environment)** | A dev environment that lives on a remote/cloud server, not your laptop. | Ghost as CDE via VPS or Cloudflare Tunnel. |
| **Tenant** | One isolated user room: own container `ghost-tenant-&lt;id&gt;`, port, CPU/RAM, storage `mounts/tenants/&lt;id&gt;`, registry `config/tenants.json`. | The WaaS primitive. |
| **Host** | The machine that runs Docker (your laptop or VPS). | The building that houses the hotel. |
| **Bridge Network** | Virtual LAN (`ghost_sandbox`) that containers share. | Tenants talk via network, but storage stays isolated. |
| **Cloudflare Tunnel** | Zero-trust remote access without opening ports. Needs `TUNNEL_TOKEN`. | Access Ghost from anywhere without firewall. |
| **MCP** | Model Context Protocol — standard for AI tools to call local services. | How agents talk to files/terminal/etc. |
| **HeLa MCP Ecosystem** | Bundle of 7 MCP servers (mitosis/genome/membrane/nucleus/ribosome/enzyme/phenotype). | Gives agents tools (filesystem, terminal, research, etc). |
| **RTK** | Token saver that rewrites shell commands via `PreToolUse` hook, saving 60–90% tokens. | Makes agent tool calls cheaper. |
| **HeLa** | Naming after Henrietta Lacks; the ecosystem’s brand across micros. | Respectful reference in the product naming. |
| **OrbStack / Docker Desktop** | macOS apps that provide a Docker daemon. OrbStack is leaner/faster. | How macOS runs Ghost. |
| **WSL2** | Windows Subsystem for Linux 2 — a Linux kernel inside Windows for Docker. | How Windows runs Ghost. |
| **Snapshot** | Archived `mounts/` as `snapshots/ghost_snapshot_*.tar.gz` + `.sha256` + `.meta.json`. Caches excluded. | Your save game. |
| **Restore** | Verified rewind from a snapshot (SHA check, atomic backup, rollback on failure). | Undo bad experiments. |
| **Cleanup Levels** | L1 `-s` stop, L2 `-v` + volumes, L3 `-a` + local images, L4 `--nuke` + GHCR + builder. | How to free disk. |
| **Builder Cache** | Docker’s stored layers for fast rebuilds. Cleared by `--nuke`. | Faster next `build`, but can be GBs. |
