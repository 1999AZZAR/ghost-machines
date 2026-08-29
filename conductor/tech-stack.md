# Technology Stack

## Infrastructure & Virtualization
- **Container Engine:** Docker 20.10+ & Docker Compose v2.0+
- **Host Resource Virtualization:** LXCFS (Linux host accurate resource metrics)
- **Base Images:**
  - Ubuntu (`ubuntu:latest`)
  - Debian (`debian:stable-slim`)
  - Alpine (`alpine:latest`)
  - Arch Linux (`archlinux:latest`)

## Orchestration & Scripting
- **Shell:** Bash (POSIX compatible orchestration scripts)
- **Networking & Tunnels:** Cloudflare Tunnel (`cloudflared`), OpenSSH
- **State Persistence:** Docker bind mounts (`mounts/`), Tar/GZip snapshot archives

## Runtimes & Languages
- **Node.js & Bun:** Modern JavaScript/TypeScript execution
- **Go 1.24:** Systems programming toolchain
- **Python 3:** Scripting, automation, and AI client libraries
- **Rust Token Killer (RTK):** Token optimization utility for agentic and CLI operations

## Editors & CLI Tooling
- **Editors:** Micro, Helix, Lazygit, Neovim
- **Navigation & Utilities:** tmux, zoxide, eza, bat, fd, ripgrep, jq, fzf, nnn, btop, fastfetch
- **AI & Protocol Integration:** Model Context Protocol (MCP) servers (`terminal`, `filesystem`, `sequentialthinking`), Gemini CLI, OpenAI Codex
