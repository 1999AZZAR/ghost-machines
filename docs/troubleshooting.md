# Troubleshooting

Start with the two commands that answer most questions:

```bash
./start.sh status     # container state, image, SSH port
./start.sh logs       # entrypoint + sshd output, follows
```

## Symptom → fix

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| `Bind for 0.0.0.0:2223 failed: port is already allocated` | another container or process holds the port | `./start.sh … -p 2225` (dual then uses 2225/2226), or `./start.sh stop` first |
| `ssh: connect to host localhost port 2223: Connection refused` | container not running, still booting, or a different port | `./start.sh status`; then `./start.sh logs` while it initializes |
| `Permission denied (publickey,password)` | `SSH_PASSWORD_AUTH=false` and no authorized key | set it back to `true` in `.env` and recreate (`./start.sh stop && ./start.sh …`), or fix the key |
| `Host key verification failed` | new container = new SSH host key | `ssh-keygen -R "[localhost]:2223"` or use `ghost-ssh` |
| `Permission denied` writing inside `~` | container UID ≠ host UID | re-run `./start.sh` (re-syncs `HOST_UID`/`HOST_GID`); last resort `sudo chown -R "$(id -u):$(id -g)" mounts/` |
| `--build` seems to do nothing | the image reference is a registry tag | drop `GHOST_IMAGE`, or use the local tag (`-e ubuntu` with no prebuilt) |
| Image rebuilt when you wanted the prebuilt | no local tag existed | use `--prebuilt`, or pull the GHCR tag first |
| `denied` / `401` pulling from GHCR | private package or anonymous rate limit | `echo $GH_TOKEN \| docker login ghcr.io -u <user> --password-stdin` |
| `htop`/`free` show host RAM | LXCFS not installed or disabled | `make setup-host` on Linux; expected on macOS/WSL (`--no-lxcfs`) |
| `permission denied … /var/run/docker.sock` | user not in the `docker` group | `sudo usermod -aG docker $USER`, then re-login |
| Agent CLI missing or stale inside | build-time download failed (offline host) | `harness-update` inside the sandbox, `./start.sh --update-harness`, or check `/var/log/ghost-harness-update.log` |
| MCP tools missing or a cell fails to start | profile cell not installed, or data dir not writable | `node /opt/hela-src/setup.mjs doctor --prefix /opt/hela`; cells install per `HELA_PROFILE` at build time |
| Container restarts in a loop | entrypoint or `sshd_config` error | `./start.sh logs`, fix, `./start.sh stop && ./start.sh …` |
| `apt`/`apk` install vanished | container was recreated | expected: bake it into a Dockerfile ([Engines](engines.md)) |
| Mount is root-owned | stale container created with a different UID | `./start.sh stop`, re-run `./start.sh`, or `sudo chown -R "$(id -u):$(id -g)" mounts/` |
| Dual mode second machine unreachable | port/name assumptions | it is `ghost-machine2` on `G2_PORT` (default 2224) |
| Tenant `add` fails with "already exists" | registry still has the id | `./tenant.sh list`, then `./tenant.sh delete <id> -y` |

## Diagnostics

```bash
./start.sh status
docker compose --profile dual --profile remote config     # fully resolved compose file
docker inspect -f '{{.State.Status}} {{.Config.Image}}' ghost-machine-single
docker exec ghost-machine-single ss -tlnp
docker exec ghost-machine-single tail -n 100 /var/log/ghost-harness-update.log
docker port ghost-machine-single
```

Log locations:

| What | Where |
| :--- | :--- |
| Entrypoint, sshd, container stdout | `./start.sh logs` / `docker logs <name>` |
| Harness refresh | `docker exec <name> cat /var/log/ghost-harness-update.log` |
| SSH auth failures | `docker exec <name> cat /var/log/auth.log` (Debian/Ubuntu) |
| OpenCode sessions | `~/.local/share/opencode/log` inside the sandbox |

## First boot is slow

The entrypoint re-syncs UID/GID, writes the home skeleton if missing, and starts a background harness refresh. On a large `mounts/` the `chown -R` pass can take a while; the container is up but sshd is not accepting yet. Watch progress with `./start.sh logs`, wait, or reduce the workspace size.

## Flaky Docker Desktop / OrbStack on macOS

Mounts over the VM filesystem are slower and can report odd ownership. If ownership problems repeat, keep sources under `~/` (not `/Volumes`), and prefer OrbStack or a Linux host for heavy builds. LXCFS is unavailable there by design.

## When all else fails

```bash
./start.sh stop
./clean.sh --nuke -y        # containers, tenants, every image tag, cache, registry
./start.sh --prebuilt debian -m single
```

If a rebuild reproduces the problem, capture `./start.sh logs` output and open an issue with the engine, mode, image reference and the first 50 log lines.
