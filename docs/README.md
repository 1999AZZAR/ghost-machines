# Documentation Index

Ghost Machines is disposable Linux sandboxes and agent workstations on Docker Compose. These docs are organised by what you are trying to do, not by feature.

**Start here:** [Getting Started](getting-started.md) — clone, start, connect, stop in five minutes.

## Where do I find…

| Question | Page |
| :--- | :--- |
| What do I need installed, and how do I get a shell? | [Getting Started](getting-started.md) |
| Prebuilt image or local build? How do I pin a version? | [Images](images.md) |
| What is inside the image, and which engine should I pick? | [Engines & Toolchain](engines.md) |
| How do I stop, pause, restart or delete without losing work? | [Lifecycle & Cleanup](lifecycle.md) |
| Which port/container do I SSH into? How do I reach a dev server? | [Connecting](connecting.md) |
| What does this environment variable do? | [Configuration](configuration.md) |
| What happens between `./start.sh` and a prompt? | [Architecture](architecture.md) |
| How do I give five people their own sandbox? | [Multi-Tenant](tenants.md) |
| Is this safe to expose? What must I change first? | [Security & Hardening](security.md) |
| Something is broken. | [Troubleshooting](troubleshooting.md) |
| What does each script do, in plain English? | [Scripts Guide](scripts.md) |
| Container, cgroup, LXCFS — what do these words mean? | [Glossary](glossary.md) |
| Should I use this instead of a VM? | [Ghost vs VM](comparison-vs-vm.md) |
| How do I modify images, add an engine or release? | [Contributing](contributing.md) |
| Just give me the commands. | [Cheatsheet](cheatsheet.md) |

## Audience paths

- **Trying it out** → Getting Started → Connecting → Lifecycle
- **Running it daily** → Cheatsheet, Configuration, then Troubleshooting when needed
- **Running it for a team** → Multi-Tenant → Security → Architecture
- **Hacking on the images** → Engines → Architecture → Contributing

## Conventions used here

- `./start.sh`, `make …` — run on the **host**, in the repo checkout.
- Commands marked "inside the sandbox" run **after** `ssh`/`docker exec`.
- Default credentials are `developer` / `ghost`; `sudo` uses the same password.
- `mounts/` is the only state that survives; everything else is disposable.

## Contributing to these docs

Docs are plain markdown in `docs/`, rendered to `docs/site/pages/` by `tools/build_site.py`. Edit the markdown, run `make docs`, and let `make test` (which includes `tests/test_docs.sh`) catch stale links, broken examples and claims that no longer match the code.
