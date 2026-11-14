# Images: Prebuilt vs Local Build

Every run uses exactly one image. `start.sh` resolves it in this order:

1. `--image <ref>` — explicit, wins over everything.
2. `--prebuilt [engine]` — `ghcr.io/1999azzar/ghost-machine-<engine>:latest`.
3. `GHOST_IMAGE` from your environment or `.env`.
4. The local build tag for the chosen engine: `ubuntu-template:latest`, `debian-template:latest`, `alpine-template:latest`, `arch-template:latest`.

**The rule that answers most confusion:** a reference containing `/` is a registry image and is **pulled**; a plain tag is a local build target and is **built**. `--build` is ignored (with a notice) whenever the reference is a registry image.

## Prebuilt images (GHCR)

Published by `.github/workflows/publish.yml` on release tags (`v*`) and on manual dispatch. Multi-arch: `linux/amd64` and `linux/arm64`.

| Engine | Reference | Approx. size |
| :--- | :--- | :--- |
| Ubuntu | `ghcr.io/1999azzar/ghost-machine-ubuntu:latest` | ~1.38 GB amd64 / 1.21 GB arm64 |
| Debian | `ghcr.io/1999azzar/ghost-machine-debian:latest` | ~1.36 GB / 1.20 GB |
| Alpine | `ghcr.io/1999azzar/ghost-machine-alpine:latest` | ~1.59 GB / 1.32 GB |
| Arch | `ghcr.io/1999azzar/ghost-machine-arch:latest` | ~1.63 GB both |

Each package carries three kinds of tag:

- `latest` — newest release, moves on every publish.
- `vX.Y.Z` — immutable release tag, use this for reproducibility.
- `latest-<short-sha>` — commit-pinned, for bisecting a regression.

```bash
# pulled automatically when missing
./start.sh --prebuilt debian -m single

# explicit reference (pull first if you want control)
docker pull ghcr.io/1999azzar/ghost-machine-debian:latest
./start.sh --image ghcr.io/1999azzar/ghost-machine-debian:latest -m single

# refresh an image you already have
./start.sh --prebuilt debian -m single --pull

# make prebuilt the default
echo 'GHOST_IMAGE=ghcr.io/1999azzar/ghost-machine-ubuntu:latest' >> .env
./start.sh -e ubuntu -m single
```

Prebuilt images are built with `HOST_UID=1000` / `HOST_GID=1000`; the entrypoint re-syncs the `developer` account to your host IDs at start, so bind mounts still match your user.

## Local build

```bash
./start.sh -e ubuntu -m single --build     # build then start
make build-ubuntu                          # build only
make build-all                             # all four engines
```

`make build-*` produces `<engine>-template:latest`. Start later without `--build` — Compose reuses the tag, and builds automatically only if the tag is missing.

## Pinning, upgrading, rolling back

Because the container is disposable and your data is on the host, upgrades are mechanical.

**Pin a version (reproducible):**

```bash
./start.sh --image ghcr.io/1999azzar/ghost-machine-ubuntu:v2.1.0 -m single
# or persist it
echo 'GHOST_IMAGE=ghcr.io/1999azzar/ghost-machine-ubuntu:v2.1.0' >> .env
```

**Upgrade:**

```bash
./start.sh stop
./start.sh --prebuilt ubuntu -m single --pull
```

**Roll back:** start with the previous tag — `./start.sh stop && ./start.sh --image ghcr.io/1999azzar/ghost-machine-ubuntu:v2.0.0 -m single`.

**What survives an upgrade:** everything in `mounts/` (home, projects, dotfiles, agent sessions). **What changes:** the container, its SSH host key (expect `Host key verification failed` once — see [Connecting](connecting.md)), and anything you installed outside `mounts/` with `apt`/`apk`/`pacman`, which is intentionally discarded. Bake permanent packages into a Dockerfile instead ([Contributing](contributing.md)).

**Local-build upgrade:** `./start.sh -e ubuntu -m single --build` rebuilds and recreates the container.

## Harnesses are never pinned

`opencode`, `agy` and `rtk` ship inside the image, but their versions float by design. The `harness-update` helper resolves each from its official upstream and installs it into `/usr/local/bin`:

| Harness | Source |
| :--- | :--- |
| `opencode` | `https://opencode.ai/v2/install` |
| `agy` | `https://antigravity.google/cli/install.sh` |
| `rtk` | `https://github.com/rtk-ai/rtk/releases/latest/download` |

It runs at image build, then at container start when the stamp is stale, then on demand:

```bash
./start.sh --update-harness   # from the host, into the running container
harness-update                # inside the sandbox: refresh everything
harness-update opencode       # one harness
harness-update --if-due       # only when the stamp is stale
```

| Variable | Default | Effect |
| :--- | :--- | :--- |
| `GHOST_HARNESS_UPDATE` | `latest` | `latest` (refresh when stale), `always` (every start), `off` (never). |
| `HARNESS_UPDATE_INTERVAL_HOURS` | `24` | Staleness window for `latest`. |

Concurrent runs serialise on a lock, refresh output goes to `/var/log/ghost-harness-update.log`, and a host-provided `agy` (mounted read-only at `/usr/local/bin/agy-host`) takes precedence when present. Pinning a harness defeats the point; if you need a frozen toolchain, pin the image tag instead.

## Which image am I actually running?

```bash
./start.sh status                                          # IMAGE column
docker inspect -f '{{.Config.Image}}' ghost-machine-single  # exact reference
docker images | grep -E 'ghost-machine|template'           # what exists locally
```

`start.sh` also announces it on every launch with the `[IMAGE]` line shown above.

## Offline / air-gapped hosts

```bash
# on a connected machine
docker pull ghcr.io/1999azzar/ghost-machine-debian:latest
docker save ghcr.io/1999azzar/ghost-machine-debian:latest | gzip > ghost-debian.tar.gz

# on the target
docker load < ghost-debian.tar.gz
./start.sh --image ghcr.io/1999azzar/ghost-machine-debian:latest -m single
```

Set `GHOST_HARNESS_UPDATE=off` there, otherwise each start spends a few seconds failing to reach upstream (harmless, but noisy in `docker logs`).
