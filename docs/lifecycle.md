# Lifecycle & Cleanup

A Ghost Machine is disposable by design: the container is cattle, `mounts/` is the pet. Every command below is about *how much* you throw away.

## State model

| Layer | Lives in | Dies when |
| :--- | :--- | :--- |
| Image | Docker's image store | `clean.sh -a`, `--nuke`, or `--build` replaces the tag |
| Container | Docker (ephemeral filesystem) | `stop`, `restart` recreates, any rebuild |
| Home / projects / dotfiles | `mounts/ubuntu1`, `mounts/ubuntu2`, `mounts/tenants/<id>` on the host | only `clean.sh --nuke --hard` |
| Config | `.env`, `docker-compose.yml` | your git checkout |

## Command matrix

| Goal | Command | Keeps |
| :--- | :--- | :--- |
| Start / create containers | `./start.sh [flags]` | `mounts/`, images, `.env` |
| Show state, image, SSH port | `./start.sh status` | — |
| Restart in place (no recreate) | `./start.sh restart` | container, everything |
| Pause (container kept, stopped) | `docker compose --profile dual stop` | container, everything |
| Resume a pause | `docker compose --profile dual start` | container, everything |
| Stop and delete containers + network | `./start.sh stop` | `mounts/`, images, `.env` |
| Delete containers + volumes | `./clean.sh -v -y` | `mounts/`, images |
| Delete everything including images | `./clean.sh -a -y` | `mounts/` |
| Purge images and work | `./clean.sh --nuke --hard -y` | nothing |
| Follow logs | `./start.sh logs` | — |
| Shell without SSH | `docker exec -it ghost-machine-single bash` | — |
| Refresh agent harnesses | `./start.sh --update-harness` | — |

Makefile shortcuts: `make start`, `make status`, `make logs`, `make restart`, `make stop`, `make prebuilt ENGINE=debian MODE=single`.

## Start and recreate

`./start.sh` is idempotent: it creates what is missing and reuses what is running. Add `--build` (local tag) or `--pull` (registry tag) to move to a newer image.

Some settings only apply at container creation:

| Setting | Applies on |
| :--- | :--- |
| Ports (`-p`), container names, tunnel token | new container → `./start.sh stop && ./start.sh …` |
| Image (`--image`, `--prebuilt`, `--pull`, `--build`) | new container |
| `GHOST_HARNESS_UPDATE`, interval | next container start (entrypoint reads it) |
| `SSH_PASSWORD_AUTH`, keys | new container (entrypoint rewrites `sshd_config`) |
| CPU/RAM limits (mode or `.env`) | new container |

Changing mode (`single` → `power`) also creates a *different* container name; the old one keeps running until you stop it. Use `./start.sh status` to see what is actually up.

## Restart, pause, resume

- `./start.sh restart` = `docker compose restart`: same container, processes restarted, filesystem and IP kept. Cheapest fix for a wedged sshd.
- Pause/resume keeps the container object (and its ephemeral filesystem) between runs:

```bash
docker compose --profile dual stop      # both profiles, safe even if unused
docker compose --profile dual start
```

- `./start.sh stop` deletes containers and the compose network. Anything installed with `apt` inside them is gone; `mounts/` is untouched.

## Logs and diagnostics

```bash
./start.sh logs                                              # compose logs, follows
docker logs -f ghost-machine-single                          # same, raw
docker exec ghost-machine-single cat /var/log/ghost-harness-update.log
docker exec ghost-machine-single journalctl -u ssh 2>/dev/null || true
```

The entrypoint is chatty on purpose: SSH key injection, user sync, harness config generation and the background harness refresh all log there. Most "it didn't start" reports are answered by the first 50 lines.

## Cleanup levels

`clean.sh` has four levels. L4 is a genuine nuke: containers, images, caches and the tenant registry. Only `--hard` touches your data.

```bash
./clean.sh                    # interactive menu
./clean.sh -s -y              # L1: stop + remove containers and network
./clean.sh -v -y              # L2: L1 + volumes
./clean.sh -a -y              # L3: L2 + local template images (GHCR stays)
./clean.sh --nuke --dry-run   # L4 preview: prints every command, changes nothing
./clean.sh --nuke -y          # L4: full purge, keeps mounts/ and snapshots/
./clean.sh --nuke --hard -y   # L4 + mounts/ and snapshots/ (data loss)
```

What L4 (`--nuke`) removes:

| Target | Detail |
| :--- | :--- |
| Containers | Main instances, the tunnel, and every `ghost-tenant-*` compose project |
| Images | All local `*-template` tags **and** every GHCR tag (`latest`, `vX.Y.Z`, `latest-<sha>`) |
| Dangling images | Only those carrying this project's OCI source label (images built from the current Dockerfiles) — other projects are untouched |
| Volumes | Compose volumes belonging to `ghost-machines` / `ghost-tenant-*` only |
| Networks | `ghost_sandbox` and any `ghost-machines_*` / `ghost-tenant-*` network |
| Build cache | `docker builder prune -af` and `docker buildx prune -af` |
| Registry | `config/tenants.json` restored to its committed (empty) state — no spurious git diff |

What it deliberately keeps: `mounts/` (your work) and `snapshots/` (your backups), unless `--hard` is passed. `--hard` deletes both and recreates the empty directories, returning the checkout to a first-run state.

Every level supports `--dry-run`, which prints the exact Docker commands without executing them, and `-y` to skip the confirmation prompt. L1–L3 warn when tenant containers exist, because they only manage the main machines.

## Backup and restore

Snapshots archive `mounts/` while skipping caches (`node_modules/.cache`, `.npm/_cacache`, `target/`, `__pycache__`, `.pytest_cache`, logs):

```bash
make snapshot                                   # snapshots/ghost_snapshot_<ts>.tar.gz
./snapshot.sh -o my_backup.tar.gz               # named archive
./snapshot.sh --all                             # include caches too

make restore
./restore.sh my_backup.tar.gz                   # verifies SHA-256, atomic rollback on failure
./restore.sh -y my_backup.tar.gz                # non-interactive
./restore.sh -k my_backup.tar.gz                # keep the pre-restore backup
```

Every snapshot writes three files: the archive, `<archive>.sha256`, and `<archive>.meta.json` (timestamp, architecture, file counts, hash). Restore validates the checksum, backs up the current mounts, and rolls back automatically if extraction fails. Tenants have their own snapshot/restore commands.
