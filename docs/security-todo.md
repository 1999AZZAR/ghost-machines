# Security TODO — Making Ghost Machines Production-Ready

> Current defaults are dev-only (`developer:ghost` / `root:ghost` `Dockerfile:94`, `PermitRootLogin yes` `entrypoint.sh:11`). This checklist closes the gaps for WaaS/multi-tenant prod.

## P0 — Must Fix Before Exposing to Tenants / Internet

- [ ] **Kill default passwords** — `Dockerfile:95` `root:ghost` + `Dockerfile:140` `developer:ghost` and `entrypoint.sh:32` `ghost` reset on every boot. Replace with: random per-tenant password generated in `tenant.sh`/`start.sh`, stored only in host `mounts/.secrets/` (600), or force key-only. Never bake password in image layer.
- [ ] **Default to key-only SSH** — flip `.env.example:15` `SSH_PASSWORD_AUTH=true` → `false`. Require `SSH_AUTH_KEY_PATH` when tunnel/remote enabled. Fail boot if no key and `TUNNEL_TOKEN` set.
- [ ] **Disable root SSH** — `Dockerfile:94` `PermitRootLogin yes` → `prohibit-password` or `no`. Tenants don't need `root@localhost` over SSH; use `sudo` inside.
- [ ] **Sudo with password** — keep `entrypoint.sh:35` `ALL=(ALL) ALL` but require password (remove `NOPASSWD` if ever added). Document that `sudo` password = generated tenant password, not `ghost`.
- [ ] **Host volume least privilege** — `docker-compose.yml:31` `./mounts/ubuntu1:/home/developer` is RW. For untrusted tenants, add `:rw` explicitly + `read_only: true` for rootfs + `tmpfs` for `/tmp`. Prevent mount escape via `..` symlinks.

## P1 — Container Hardening

- [ ] **Drop capabilities & add seccomp** — add to `docker-compose.yml`:
  ```yaml
  cap_drop: [ALL]
  cap_add: [CHOWN, SETUID, SETGID] # minimal for entrypoint chown
  security_opt: [no-new-privileges:true, seccomp:unconfined] # or custom seccomp.json
  read_only: true
  tmpfs: [/tmp:rw,noexec,nosuid,size=256m]
  ```
- [ ] **No privileged / host mounts** — audit no `--privileged`, no `/var/run/docker.sock` mount (currently clean, keep it).
- [ ] **LXCFS read-only already** `docker-compose.yml:26` `:ro` ✔️ keep it; add `nodev/nosuid/noexec` if remounted.
- [ ] **SSH hardening in `entrypoint.sh:10`** — enforce `PasswordAuthentication no`, `PermitEmptyPasswords no`, `X11Forwarding no`, `AllowTcpForwarding no` (unless needed), `ClientAliveInterval 300`.
- [ ] **Image pinning** — `Dockerfile:7` `FROM ubuntu:latest` → `ubuntu:24.04` (or `noble-20241011`) with SHA pin. Same for `debian:stable-slim`, `alpine:latest`, `archlinux:latest`.

## P2 — WaaS / Multi-Tenant

- [ ] **Per-tenant network isolation** — `tenant.sh` already creates `./mounts/tenants/<id>` ✔️ but `sandbox_net` `docker-compose.yml:101` is shared. Create per-tenant bridge or `network: tenant_<id>_net` + `icc: false` to block tenant-to-tenant `ghost-machine1 → ghost-machine2`.
- [ ] **Per-tenant SSH port + key** — `tenant.sh add alice --port` must auto-pick free port and generate `authorized_keys` per tenant, not copy host `/root/.ssh/authorized_keys` to all.
- [ ] **Resource quotas already `cpus/memory`** ✔️ add `pids_limit: 512` and `ulimits` to stop fork bombs.
- [ ] **Secrets per tenant** — `TUNNEL_TOKEN` in `.env` is global. For WaaS, store per-tenant token in `mounts/tenants/<id>/.env` (600), not shared compose file.
- [ ] **Snapshot encryption** — `snapshot.sh` tar is plaintext. Add `gpg --symmetric` or `age` option for tenant backups before uploading.

## P3 — Host & Supply Chain

- [ ] **`.env` 600 enforcement** `start.sh:17` already does `chmod 600` ✔️ — also add to `clean.sh` verify.
- [ ] **HeLa/Conductor pin** — `Dockerfile:98` `git clone --depth=1 hela-mcp-ecosystem` + `Dockerfile:115` `conductor.git` track `main`. Pin to tag/commit via `ARG HELA_REF=vX.Y.Z` for reproducibility + `sha256` verify.
- [ ] **No baked secrets in layers** — audit `docker history` shows no `TUNNEL_TOKEN`/`GHOST_USER` password in `ENV`. Already clean.
- [ ] **Host LXCFS + Docker setup** — `setup-host.sh` should not `curl | bash` without checksum (check current script).
- [ ] **Logging/audit** — add `sshd` `LogLevel VERBOSE` + ship `auth.log` to host `mounts/logs/<tenant>/` for breach forensics. Document retention.

## Verification

```bash
make lint              # shellcheck + compose validate
./tests/test_m1_security.sh  # UID/GID + ssh perms
docker scout cves ubuntu-template:latest  # or trivy image
grep -r "ghost" Dockerfile* entrypoint.sh --include="*.sh" # no hardcoded ghost left
```

## Out of Scope (needs VM, not container)

- Untrusted binary detonation, kernel exploit testing → use real VM / Firecracker microVM, not Ghost. Documented in `docs/comparison-vs-vm.md`.
