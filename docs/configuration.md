# Configuration

All configuration is environment variables. `.env` in the repo root is the canonical place; `start.sh` reads it and passes values to Docker Compose.

## Precedence

1. CLI flags (`./start.sh -e debian -m single -p 2225 …`)
2. Variables exported in your shell
3. `.env`
4. Defaults in `docker-compose.yml`

`start.sh` hardens `.env` to `600` on every run if it is more permissive.

## Core variables

| Variable | Default | Effect | Applies on |
| :--- | :--- | :--- | :--- |
| `GHOST_USER` | `developer` | Non-root account inside the sandbox. | create |
| `HOST_UID` | host `id -u` | UID the account is synced to, so mounts match your user. | create |
| `HOST_GID` | host `id -g` | Same for the group. | create |
| `GHOST_IMAGE` | engine default | Image reference; anything containing `/` is pulled, a plain tag is built. | create |
| `GHOST_DOCKERFILE` | engine default | Dockerfile used when building. Set automatically by `-e`/`--prebuilt`. | build |

## Ports and names

| Variable | Default | Effect |
| :--- | :--- | :--- |
| `G1_PORT` | `2223` | Host port for the first machine (`-p N` sets this). |
| `G2_PORT` | `2224` | Host port for the second machine in dual mode (`-p N` sets `N+1`). |
| `G1_NAME` | `ghost-machine1` | Container name in dual mode. |
| `G2_NAME` | `ghost-machine2` | Second container name in dual mode. |

In single/power/half mode the names are fixed by `start.sh`: `ghost-machine-single`, `ghost-machine-power`, `ghost-machine-half`.

## Access

| Variable | Default | Effect | Applies on |
| :--- | :--- | :--- | :--- |
| `SSH_PASSWORD_AUTH` | `true` | `false` disables password login entirely (key-only). Lock-out risk — see [Connecting](connecting.md). | create |
| `SSH_AUTH_KEY_PATH` | auto-detected | Host public key to authorize. Auto-detected from `~/.ssh/id_ed25519.pub`, `~/.ssh/id_rsa.pub`, `~/.ssh/authorized_keys`. | create |
| `TUNNEL_TOKEN` | empty | Cloudflare Tunnel token. A real token (>10 chars) enables the `remote` profile. | create |

## Resources

| Variable | Default | Effect |
| :--- | :--- | :--- |
| `G1_CPU` | `1.0` | CPU quota for the first machine. `start.sh` overwrites it per mode. |
| `G1_MEM` | `8G` | Memory limit for the first machine. |
| `G2_CPU` | `1.0` | CPU quota for the second machine (dual only). |
| `G2_MEM` | `8G` | Memory limit for the second machine (dual only). |

Mode presets (the mode always wins over a hand-edited value):

| Mode | Instances | CPU | RAM | Container names |
| :--- | :---: | :---: | :---: | :--- |
| `single` | 1 | 1.0 | 8G | `ghost-machine-single` |
| `dual` | 2 | 1.0 each | 8G each | `ghost-machine1`, `ghost-machine2` |
| `power` | 1 | 2.0 | 16G | `ghost-machine-power` |
| `half` | 1 | 50% host | 50% host | `ghost-machine-half` |

To pin a custom value, start Compose yourself with the variables you want after selecting the mode.

## Agents and MCP

| Variable | Default | Effect |
| :--- | :--- | :--- |
| `GHOST_HARNESS_UPDATE` | `latest` | `latest` = refresh stale binaries at start, `always` = every start, `off` = never. |
| `HARNESS_UPDATE_INTERVAL_HOURS` | `24` | Staleness window for `latest`. |
| `MCP_ECOSYSTEM_LOCAL_PATH` | `/dev/null` | Mount a local `hela-mcp-ecosystem` clone at `/opt/mcp-ecosystem-local` for development. |

## Tenant variables

`tenant.sh` sets these itself; they are listed for completeness and overrides. Defaults live in `templates/docker-compose.tenant.yml`.

| Variable | Default | Effect |
| :--- | :--- | :--- |
| `TENANT_IMAGE` | engine tag | Image for a tenant (overrides engine default). |
| `TENANT_DOCKERFILE` | `Dockerfile.debian` | Dockerfile used when building a tenant. |
| `TENANT_USER` | `developer` | Workspace user. |
| `TENANT_PORT` | auto (`>=2225`) | Host SSH port. |
| `TENANT_CPU` | `2.0` | CPU quota. |
| `TENANT_MEM` | `4G` | Memory limit. |
| `TENANT_MOUNT_PATH` | `mounts/tenants/<id>` | Persistent workspace. |
| `TENANT_AUTH_KEY_PATH` | auto | Authorized public key. |

## LXCFS

`start.sh` detects `/var/lib/lxcfs/proc` and mounts `cpuinfo`, `meminfo`, `stat`, `swaps` and `uptime` read-only into the sandbox so resource tools report cgroup limits. With LXCFS absent (macOS, WSL, plain Docker without lxcfs) the mounts fall back to `/dev/null`, which Docker tolerates. Force the fallback with `--no-lxcfs`.

## Profiles

| Profile | Enabled by | Adds |
| :--- | :--- | :--- |
| `dual` | `-m dual` / `./start.sh dual` | second machine (`ghost2`) |
| `remote` | valid `TUNNEL_TOKEN` | `cloudflared` tunnel container |

## Passing arguments to Compose

Anything unknown to `start.sh` is forwarded:

```bash
./start.sh -e debian -m single -- --force-recreate
docker compose --profile dual config      # inspect the resolved configuration
```

## Minimal `.env`

```bash
GHOST_USER=developer
G1_PORT=2223
SSH_PASSWORD_AUTH=true
# TUNNEL_TOKEN=...
# GHOST_IMAGE=ghcr.io/1999azzar/ghost-machine-ubuntu:v2.1.0
# GHOST_HARNESS_UPDATE=latest
```

Everything is optional; the defaults work on a laptop. `.env.example` mirrors this file — if you add a variable there, add it here too (the docs test enforces that).
