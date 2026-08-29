# Specification: M5 HeLa MCP Ecosystem Integration

## Overview
This track integrates the complete **HeLa MCP Ecosystem** (`https://github.com/1999AZZAR/hela-mcp-ecosystem`) into Ghost Machines, using the designated **`headless-server`** profile across all 4 OS engines (Ubuntu, Debian, Alpine, Arch).

## Included HeLa Cellular MCP Servers (Core 7 Headless Stack)
1. **HeLa Mitosis (`hela-mitosis`)**: Dynamic routing, sequential thinking reasoning, prompt decomposing (`chaining-mcp-server`).
2. **HeLa Genome (`hela-genome`)**: Living SQLite knowledge graph (`memory.db`), milestone tracking (`Project-Guardian-mcp-server`).
3. **HeLa Membrane (`hela-membrane`)**: Sandboxed workspace file operations, recursive search, archive extraction (`filesystem-mcp-server`).
4. **HeLa Nucleus (`hela-nucleus`)**: Command execution, subshell isolation, RTK token-optimized terminal (`terminal-mcp-server`).
5. **HeLa Ribosome (`hela-ribosome`)**: Interactive PTY session multiplexer, Regex event hooks (`menager-mcp-server`).
6. **HeLa Enzyme (`hela-enzyme`)**: Unified Google Custom Search + cached Wikipedia fact-checking (`research-mcp-server`).
7. **HeLa Phenotype (`hela-phenotype`)**: UI/UX design tokens, OKLCH palettes, Tailwind & component synthesis (`the-designer`).

## Functional Requirements
1. **Automated Ecosystem Build in Dockerfiles:**
   - Clone `hela-mcp-ecosystem` to `/opt/mcp-ecosystem` (aliased to `/root/MCPservers` and accessible to `${GHOST_USER}`).
   - Run `./setup.sh --profile headless-server --client antigravity --non-interactive` (and generate client configs for Antigravity, Cursor, and Claude).
   - Install unified CLI wrapper binaries into `/usr/local/bin/` (`mcp-mitosis`, `mcp-genome`, `mcp-membrane`, `mcp-nucleus`, `mcp-ribosome`, `mcp-enzyme`, `mcp-phenotype`, with legacy `mcp-terminal` and `mcp-filesystem` aliases preserved).
2. **Configuration & State Synchronization:**
   - Store generated MCP configurations in `/root/.mcp/config.json` and `/home/${GHOST_USER}/.mcp/config.json`.
   - Update `docker-compose.yml` and `.env.example` to optionally allow mounting local development workspace `/home/azzar/project/MCPservers/mcp-ecosystem`.
3. **Automated Verification:**
   - Create `tests/test_m5_hela_mcp.sh` to verify syntax, config generation, CLI wrapper definitions, and build scripts.

## Acceptance Criteria
- All 4 Dockerfiles configure the full 7-server HeLa headless stack.
- Global binary commands (`mcp-mitosis`, `mcp-genome`, etc.) are linked and executable.
- Client configurations are pre-generated inside the images.
