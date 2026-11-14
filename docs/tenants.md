# Multi-Tenant (WaaS)

`tenant.sh` turns one host into a workspace-as-a-service box: each user gets an isolated container, its own SSH port, its own storage under `mounts/tenants/<id>`, and hard CPU/RAM quotas. Tenants are independent of the main `start.sh` machines — separate lifecycle, separate cleanup.

## Isolation guarantees

| Layer | Guarantee |
| :--- | :--- |
| Storage | Each tenant mounts only `mounts/tenants/<id>`; no path is shared between tenants. |
| Compute | cgroup CPU quota and memory limit per container (`--cpu`, `--mem`). |
| Network | Own published SSH port (auto-allocated from 2225 upward). |
| Lifecycle | Start/stop/restart/snapshot/delete one tenant without touching the others. |
| Credentials | Own workspace user and own authorized key. |

What is **not** isolated: the kernel, Docker itself, and the host. A kernel-level escape affects everyone — see [Security](security.md) before giving tenants to untrusted people.

## Provision

**Prebuilt image** (fast, no build):

```bash
./tenant.sh add alice --prebuilt --engine debian --cpu 2.0 --mem 4G --port 2225
```

**Local build** (slow, first time only):

```bash
./tenant.sh add bob --engine arch --build --cpu 4.0 --mem 8G
```

**Explicit image** (pin a release):

```bash
./tenant.sh add carol --image ghcr.io/1999azzar/ghost-machine-ubuntu:v2.1.0
```

`add` flags:

| Flag | Default | Meaning |
| :--- | :--- | :--- |
| `-e`, `--engine` | `debian` | `ubuntu`, `debian`, `alpine`, `arch` |
| `-p`, `--port` | auto ≥ 2225 | Host SSH port |
| `-c`, `--cpu` | `2.0` | CPU quota |
| `-m`, `--mem` | `4G` | Memory limit |
| `-u`, `--user` | `developer` | Workspace account |
| `-k`, `--pubkey` | auto-detected | Authorized public key |
| `--prebuilt` | off | Use the GHCR image for the engine |
| `--image <ref>` | — | Explicit reference (pulled if missing) |
| `--pull` | off | Force-pull before starting |
| `-b`, `--build` | off | Build locally |
| `-y`, `--yes` | off | Non-interactive |

A registry reference (contains `/`) is pulled, never built; `--build` is ignored with a notice. No `--build` and no local tag means Compose builds once, then reuses it.

## Operate

| Command | Effect |
| :--- | :--- |
| `./tenant.sh list` | Registry view: id, engine, port, image, container, storage size |
| `./tenant.sh stats` | Live CPU/RAM per tenant (`stats <id>` for one) |
| `./tenant.sh stop alice` | Stop the container; workspace and port assignment kept |
| `./tenant.sh start alice` | Start it again |
| `./tenant.sh restart alice` | Restart in place |
| `./tenant.sh exec alice <cmd>` | Run a command inside the container |
| `./tenant.sh snapshot alice` | Archive the workspace + checksum + metadata |
| `./tenant.sh restore alice snapshots/<file>.tar.gz` | Restore (validates checksum) |
| `./tenant.sh delete alice -y` | Remove container **and** workspace |
| `./tenant.sh delete alice --archive -y` | Snapshot first, then remove |

Connect exactly like the main machines, on the tenant's port:

```bash
ssh -p 2225 alice@localhost     # user as configured, password: ghost
```

## Registry

Tenants are tracked in `config/tenants.json` (committed; safe to inspect, do not hand-edit while a command runs):

```json
{
  "version": "1.0",
  "tenants": {
    "alice": {
      "id": "alice",
      "engine": "debian",
      "image": "ghcr.io/1999azzar/ghost-machine-debian:latest",
      "container_name": "ghost-tenant-alice",
      "project_name": "ghost-tenant-alice",
      "port": 2225,
      "cpu_limit": "2.0",
      "mem_limit": "4G",
      "username": "developer",
      "mount_path": "/…/mounts/tenants/alice",
      "created_at": "2026-08-30T10:00:00Z",
      "status": "running"
    }
  }
}
```

Each tenant is its own Compose project (`-p ghost-tenant-<id>`) built from `templates/docker-compose.tenant.yml`, which is why they never interfere with each other or with `start.sh`.

## Snapshots and upgrades

```bash
./tenant.sh snapshot alice
# snapshots/snapshot_alice_<timestamp>.tar.gz
# snapshots/snapshot_alice_<timestamp>.tar.gz.sha256
# snapshots/snapshot_alice_<timestamp>.tar.gz.meta.json
```

Restores validate the checksum before extracting. To move a tenant to a newer image: snapshot, `delete --archive`, then `add` again with the same id and a pinned `--image`. The archive is the source of truth, not the old container.

## Deleting someone's work

`delete` removes the container *and* `mounts/tenants/<id>` — unrecoverable. `--archive` snapshots first. `-y` skips the confirmation prompt, so scripts should always pair the two.

## Cleanup interactions

`clean.sh` cleans only the main machines. Tenants are removed one by one with `tenant.sh delete`. If you nuke Docker (`clean.sh --nuke`), tenant containers disappear but `mounts/tenants/*` and `config/tenants.json` survive; `tenant.sh list` will show stale entries, and `start <id>`/`delete <id>` re-create or prune them.
