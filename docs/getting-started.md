# Getting Started

From zero to a shell in about five minutes. Everything below is copy-paste.

**You need:** Docker Engine 20.10+ with Compose v2, on Linux, macOS (Docker Desktop/OrbStack) or Windows (WSL2), `x86_64` or `arm64`. LXCFS is optional and Linux-only.

## Step 1 — Clone

```bash
git clone https://github.com/1999AZZAR/ghost-machines.git
cd ghost-machines
```

## Step 2 — Prepare the host (Linux, once)

Installs LXCFS so `htop`/`free` inside the sandbox show the container's limits instead of the host's totals. On macOS and WSL this step is skipped automatically, because those hosts cannot mount LXCFS.

```bash
make setup-host      # or ./setup-host.sh
```

## Step 3 — Pick an image source

| | Prebuilt (GHCR) | Local build |
| :--- | :--- | :--- |
| First run | ~1 minute (pull) | 5–15 minutes (build) |
| Size | 1.2–1.6 GB per engine | same, plus build cache |
| Needs this repo's Dockerfiles | No | Yes |
| Best for | trying it, CI, production | hacking on the image |

```bash
./start.sh --prebuilt ubuntu -m single      # pull the published image
./start.sh -e ubuntu -m single --build      # build it locally
```

`start.sh` prints which one it resolved before starting:

```text
[IMAGE] ghcr.io/1999azzar/ghost-machine-ubuntu:latest (GHCR prebuilt, no local build)
[IMAGE] ubuntu-template:latest (local build from Dockerfile)
```

Details, tags and pinning: [Images](images.md).

## Step 4 — Start

```bash
./start.sh                                  # interactive: asks engine + mode
./start.sh --prebuilt ubuntu -m single      # 1 machine  — 1 CPU / 8 GB
./start.sh -e debian -m dual --build        # 2 machines — 1 CPU / 8 GB each
./start.sh -e alpine -m power -p 2225       # 1 machine  — 2 CPU / 16 GB
```

`start.sh` syncs your host UID/GID into the `developer` account, authorizes your SSH key, wires LXCFS, and prints the resulting container name, image and SSH port.

## Step 5 — Connect

```bash
ssh -p 2223 developer@localhost     # password: ghost   (sudo password: ghost)
```

| Mode | Container | Port |
| :--- | :--- | :---: |
| Dual (1st) | `ghost-machine1` | 2223 |
| Dual (2nd) | `ghost-machine2` | 2224 |
| Single | `ghost-machine-single` | 2223 |
| Power | `ghost-machine-power` | 2223 |
| Half | `ghost-machine-half` | 2223 |

Not sure which port? `./start.sh status` prints the container, image and a ready-to-paste `ssh` line. Other access paths (keys only, editors, port-forwarding a dev server, Cloudflare Tunnel): [Connecting](connecting.md).

## Step 6 — Stop, resume, remove

```bash
./start.sh status     # state, image, SSH port
./start.sh logs       # follow entrypoint/sshd output
./start.sh restart    # restart in place
./start.sh stop       # remove containers + network — mounts/, images, .env stay
```

Your work lives in `mounts/` on the host, never inside the container. `stop`, image rebuilds and even `clean.sh` leave it intact; only `./clean.sh --nuke --hard` wipes it. Full matrix: [Lifecycle](lifecycle.md).

## Where next

- **Hacking on the image, package list, engine differences** → [Engines & Toolchain](engines.md)
- **Every `.env` knob** → [Configuration](configuration.md)
- **Multiple users on one host** → [Multi-Tenant](tenants.md)
- **Before exposing it to the internet** → [Security](security.md)
- **Something broke** → [Troubleshooting](troubleshooting.md)
