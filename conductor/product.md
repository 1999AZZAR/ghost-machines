# Product Definition

## Vision
**Ghost Machines** is a lightweight, semi-immutable containerized development environment orchestrator designed for predictable, reproducible, and portable engineering workflows across heterogeneous host operating systems (Linux, macOS, Windows/WSL2) and CPU architectures (x86_64, aarch64).

## Core Philosophy: "Cattle, Not Pets" (Semi-Immutable Architecture)
1. **Immutable Core (Docker Images):** OS base, core development toolchains, runtimes, MCP servers, and system utilities are packaged as read-only image layers.
2. **Decoupled Mutable State (Persistent Mounts):** User source code, local caches, and scratchpads reside in `mounts/`, allowing environments to be destroyed, upgraded, or regenerated in seconds with zero data loss.
3. **Hardware Agnostic & Zero Configuration:** Dynamic architecture detection, adaptive CPU/RAM scaling modes (Dual, Single, Power, Half-Host), and host LXCFS integration.

## Key Features & Capabilities
- **Multi-Engine Distribution Support:** Pre-configured Dockerfiles for Ubuntu (feature-rich), Debian (slim & stable), Alpine (ultra-lightweight), and Arch Linux.
- **Dynamic Resource Sizing:**
  - *Dual Mode:* 2 isolated instances (1 CPU, 8 GB RAM each) for distributed workflows.
  - *Single Mode:* 1 instance (1 CPU, 8 GB RAM) for minimal resource footprint.
  - *Power Mode:* 1 instance (2 CPU, 16 GB RAM) for heavy computation / compilation.
  - *Half-Host Mode:* Dynamic host-adaptive scaling (50% host CPU / 50% host RAM).
- **Comprehensive Developer Toolchain:** Modern CLI stack (Node.js, Go 1.24, Python 3, Bun, RTK, Helix, Micro, Lazygit, tmux, eza, zoxide, ripgrep, fd, jq, fastfetch, btop).
- **AI & MCP Ready:** Native pre-configuration for MCP servers (Terminal, Filesystem, Sequential Thinking) and AI integration tools (Gemini CLI, OpenAI Codex, RTK).
- **Zero-Trust Remote Connectivity:** Optional seamless integration with Cloudflare Tunnel (`cloudflared`) for secure remote access without port exposure.
- **Portability & Recovery:** Integrated snapshot and restore utilities (`snapshot.sh`, `restore.sh`) for cross-machine synchronization.
