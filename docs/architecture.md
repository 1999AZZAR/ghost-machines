# Architecture

Three files define everything: `docker-compose.yml` (topology), the four `Dockerfile*` (image content), and the shell scripts (orchestration and first boot). No external state, no control plane, no agents on the host.

## Components

```text
host                                    docker
─────────────────────────────────────   ──────────────────────────────────────────
start.sh / tenant.sh
  ├─ resolve engine, mode, image   ──▶   docker compose (profile: dual?, remote?)
  ├─ UID/GID sync, key discovery         ├─ ghost1        ← image, volume mounts
  ├─ LXCFS detection                     ├─ ghost2        ← profile: dual
  └─ port / name / quota selection       └─ cloudflared   ← profile: remote (TUNNEL_TOKEN)
                                              │
                                      container entrypoint.sh (PID 1 side)
                                        ├─ sshd config + host keys
                                        ├─ authorized_keys injection
                                        ├─ developer user + sudoers + UID/GID sync
                                        ├─ ~/ skeleton, aliases, fastfetch, oh-my-bash
                                        ├─ MCP configs, Conductor links, RTK hooks
                                        ├─ agy host-mount resolution
                                        ├─ harness-update (background)
                                        └─ exec sshd -D
```

## Boot sequence

What actually happens between `./start.sh` and a prompt, in order:

1. **Shell preflight** (`start.sh`) — UID/GID detection, `.env` permission hardening, SSH key discovery, host `agy` discovery, LXCFS detection, CPU/RAM calculation.
2. **Resolution** — engine → Dockerfile + image tag, mode → container name/quotas/ports, registry vs local image (pull or build).
3. **Compose** — `docker compose up -d` with the right profiles; LXCFS files and `mounts/<instance>` are bind-mounted in.
4. **Entrypoint** (`/entrypoint.sh`, runs as root) — SSH host keys generated if missing, `PasswordAuthentication` set from `SSH_PASSWORD_AUTH`, `/root` and `/home/<user>` prepared.
5. **User setup** — `developer` UID/GID re-synced to `HOST_UID`/`HOST_GID`, password set, sudoers entry written, `authorized_keys` copied with `0600`.
6. **Home skeleton** — `.bashrc`/`.bash_aliases`/`.profile`, oh-my-bash, alias-hub, neofetch ASCII, fastfetch config, all written only when absent so your files survive.
7. **Agent wiring** — the single `hela-runtime` MCP endpoint is copied into `~/.mcp/config.json` and `~/.config/opencode/opencode.json` if missing, Conductor is symlinked, and RTK rewrite hooks are installed for Antigravity/Claude/OpenCode. The runtime advertises the profile's cells and starts each only when a tool is called.
8. **Harness refresh** — `harness-update --if-due` starts in the background and logs to `/var/log/ghost-harness-update.log`; startup never waits on the network.
9. **sshd** — `exec /usr/sbin/sshd -D` becomes the container process.

Because steps 4–8 touch the bind-mounted home, a restart is not instant on a large workspace the first time; subsequent starts skip existing files.

## Resource footprint

Measured on an 8 GB / 1 CPU sandbox (Ubuntu engine, LXCFS enabled):

| State | Processes | CPU | Memory | Memory % of 8 GB |
| :--- | :--- | :---: | :---: | :---: |
| Idle (sshd waiting) | container standby | 0.00% | ~73.5 MiB | 0.90% |
| Active agent (opencode + 7 MCP daemons) | ~65 PIDs | ~1.99% | ~1,002 MiB | 12.23% |

Even fully loaded, the agent stack leaves roughly 7 GB for compilers and builds. Numbers are a snapshot of a specific host and workload, not a guarantee — `docker stats` is the source of truth on yours.

## Mounts

| Host path | Container path | Mode | Purpose |
| :--- | :--- | :--- | :--- |
| `mounts/ubuntu1` (or per mode) | `/home/developer` | rw | Your persistent work: dotfiles, projects, agent sessions. |
| `entrypoint.sh` | `/entrypoint.sh` | ro | First-boot logic, editable without rebuilding the image. |
| `~/.ssh/*.pub` | `/root/.ssh/authorized_keys` | ro | Key-based login. |
| `hela-mcp-ecosystem` clone | `/opt/mcp-ecosystem-local` | ro | Optional local MCP development. |
| host `agy` | `/usr/local/bin/agy-host` | ro | Host binary wins when present. |
| `/var/lib/lxcfs/proc/*` | `/proc/{cpuinfo,meminfo,stat,swaps,uptime}` | ro | Accurate resource reporting. |

Nothing else crosses the boundary: no Docker socket, no privileged mode, no host PID namespace.

## Network

One bridge network (`ghost_sandbox`), one published port per machine (22 → `G1_PORT`/`G2_PORT`), DNS pinned to `1.1.1.1`/`8.8.8.8`. Outbound traffic is unrestricted; inbound is SSH only (or `cloudflared` when the remote profile is active). Applications inside the sandbox are reached with SSH port-forwarding, not published ports ([Connecting](connecting.md#reaching-services-inside-the-sandbox)).

## Inside the image

| Path | Content |
| :--- | :--- |
| `/usr/local/bin/opencode`, `agy`, `antigravity`, `rtk` | Agent harnesses, refreshed by `harness-update`. |
| `/usr/local/bin/mcp-*` | Per-cell launchers (`mcp-mitosis` … `mcp-plastid`) plus `mcp-runtime`, all through `launch.mjs`. |
| `/opt/hela` | Managed HeLa installation: the selected profile's cells, runtime, data and workspace (writable by the sandbox user). |
| `/opt/hela-src` | Installer checkout, used by `setup.mjs doctor` and upgrades. |
| `/opt/conductor` | Google Conductor plugin + skills. |
| `/usr/local/bin/harness-update` | Version resolver ([Images](images.md#harnesses-are-never-pinned)). |

State that must survive belongs in `/home/developer` (the bind mount). Everything else is image or container state and is expected to be replaced.

## Extending

- **New package** → engine Dockerfile, rebuild ([Engines](engines.md)).
- **New service** → `docker-compose.yml`; keep it behind a profile if it is optional.
- **New first-boot step** → `entrypoint.sh` (bind-mounted, so no rebuild needed) and add an assertion to `tests/test_m1_security.sh`.
- **New engine** → copy a Dockerfile, update `start.sh`, `clean.sh`, `tenant.sh`, the publish matrix, and the docs table ([Contributing](contributing.md)).
