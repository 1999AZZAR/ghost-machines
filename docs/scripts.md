# Scripts Guide (Beginner Friendly)

Think of Ghost Machines as a hotel for developers. Each script is a staff member.

## start.sh — Front Desk

**What:** Starts your private workspace (a container). Handles login keys and picks which Linux flavor to use.

**Plain:** Like choosing a hotel room type — Ubuntu (standard), Debian (small), Alpine (tiny), Arch (newest).

**How:**
```bash
./start.sh                        # asks: which room? how many?
./start.sh -e ubuntu -m single    # ubuntu, 1 machine, no questions
```

Then connect: `ssh -p 2223 developer@localhost` (password `ghost`).

## tenant.sh — Hotel Manager

**What:** Creates separate rooms for different people on the same server. Each person gets own storage (`mounts/tenants/alice`), own door (SSH port), own CPU/RAM.

**Plain:** Alice and Bob can work at same time without seeing each other's files.

**How:**
```bash
# Fast way (download ready-made room):
docker pull ghcr.io/1999azzar/ghost-machine-ubuntu:latest
./tenant.sh add alice --engine ubuntu

# Build from scratch (slower):
./tenant.sh add bob --engine arch --build

# Manage:
./tenant.sh list
./tenant.sh stats        # see CPU/RAM use
./tenant.sh delete bob -y
```

## snapshot.sh & restore.sh — Backup & Undo

**What:** `snapshot.sh` zips your work, skipping junk like `node_modules`. Makes a checksum so you know it's not broken. `restore.sh` brings it back and keeps a safety copy.

**How:**
```bash
./snapshot.sh                      # creates snapshots/ghost_snapshot_*.tar.gz
./restore.sh                       # picks a backup and restores
```

## clean.sh — Housekeeping

**What:** Shuts down and cleans up. 4 levels: just stop, clear rooms, throw away images, nuke GHCR + builder. Add `--hard` with `--nuke` to also wipe `mounts/` (true 1st-user).

```bash
./clean.sh           # menu — choose level (5 options)
./clean.sh -a -y     # deep clean, no questions
./clean.sh --nuke --hard -y  # full nuke + mounts/
```

## setup-host.sh — Building Setup (once)

**What:** Prepares your computer to show correct RAM/CPU inside containers (via LXCFS). Only needed once on Linux.

```bash
./setup-host.sh
```

## entrypoint.sh — Room Butler (automatic)

**What:** Runs *inside* the container when it starts. Sets up keys, passwords, shell themes. You never run it yourself — Docker calls it.

## aliases.sh — Shortcuts

**What:** Adds nicknames for long commands.

```bash
source aliases.sh
ghost-status         # see what's running
ghost-ssh single     # quick SSH
```

Put `source /path/to/ghost-machines/aliases.sh` in `~/.bashrc` to keep them.
