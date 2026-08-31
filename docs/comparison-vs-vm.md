# Ghost Machines vs Regular VM

> When to use container sandboxes vs hardware VMs. Extended from `README.md` to avoid bloat.

## TL;DR

- **Ghost Machines**: Disposable Linux *container* sandbox on your host kernel. Fast, cheap, reproducible. One `make start`.
- **Regular VM**: Full hardware virtualization with its own kernel. Slow, heavy, strongly isolated. Boots an OS image.

They solve different problems. Not replacements.

## Architecture

| | Ghost Machines | Regular VM |
|---|---|---|
| Engine | Docker + `docker-compose.yml:1` | Hypervisor (KVM/QEMU/VirtualBox/VMware/Hyper-V) |
| Kernel | Shared with host | Own kernel |
| Base images | `ubuntu/debian/alpine/arch` `Dockerfile*` | Any OS incl. Windows/BSD |
| Boot time | ~1-2s | 30-120s |
| Idle overhead | `~73.5 MiB / 0% CPU` (README benchmark) | 500MB-2GB + vCPU reservation |

## Pros / Cons

### Ghost Machines ✔️

- **IaC & reproducibility**: `Dockerfile` + `entrypoint.sh:1` + `start.sh:9` UID/GID sync = no "works on my machine"
- **Near-zero cost**: 10 tenants on one 32GB box via `tenant.sh` + `deploy.resources.limits`
- **Batteries included**: Go/Rust/Node/Bun/Helix + HeLa 7 MCP + `agy/opencode/kilo/rtk` pre-wired
- **Snapshots**: `snapshot.sh` tar + `sha256` + atomic `restore.sh` rollback, caches excluded
- **LXCFS**: `docker-compose.yml:26` mounts make `free/htop` show container limits, not host
- **Remote**: `cloudflared` tunnel `docker-compose.yml:88` without opening ports

### Ghost Machines ❌

- **Weak isolation**: container escape = host compromise. Not for hostile/malware
- **Linux-only userland**: can't test Windows drivers, custom kernels, `systemd` edge cases
- **Shared kernel syscalls**: `seccomp/apparmor` still host-dependent

### Regular VM ✔️

- **Strong isolation**: hypervisor boundary, safe for untrusted code
- **Kernel fidelity**: test kernel modules, `iptables/nftables`, different distros/kernels
- **OS flexibility**: Windows, BSD, etc.

### Regular VM ❌

- **Heavy**: disk images 5-20GB, RAM pinned, slow snapshot/clone
- **Drift**: manual setup unless you add Packer/Vagrant/Ansible
- **No density**: 1 VM per user = expensive for teams/classrooms
- **Toolchain is DIY**: you install compilers/agents yourself

## Decision Matrix

| Need | Pick |
|---|---|
| Disposable dev env for coding/agents, need 5 identical workstations in 10s | Ghost |
| Classroom / VPS WaaS for 20 students on one host | Ghost (`tenant.sh add alice --engine debian --cpu 2 --mem 4G`) |
| CI parity with prod Linux userland | Ghost |
| Run Windows app / test BSD / kernel driver | VM |
| Detonate untrusted binary / malware analysis | VM (or Firecracker) |
| Need bare-metal perf but isolated kernel | MicroVM (Firecracker) — middle ground |

## Cost Example (16GB host)

- Ghost `dual` mode: 2 x `1 CPU / 8GB` containers idle ~147 MiB total = ~15GB left for builds
- 2 VMs `2 vCPU / 4GB` each: ~9GB pinned before you open an editor

## Security Note

Defaults `root:ghost` / `developer:ghost` `Dockerfile:94` + `PermitRootLogin yes` are dev-only. For multi-tenant prod: set `SSH_PASSWORD_AUTH=false` in `.env`, rotate passwords, mount `authorized_keys` only (`entrypoint.sh:25`).

## Further Reading

- `README.md` — quick start, engines, modes
- `docs/architecture.md` (planned) — C4 + LXCFS details
- `conductor/` — internal track docs (gitignored, local only)
