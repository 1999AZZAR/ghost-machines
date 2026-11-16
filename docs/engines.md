# Engines & Toolchain

Four base distros, one identical developer surface. Pick by package manager and libc, not by features — the toolchain is the same everywhere.

| Engine | Base image | Package manager | Flag | Dockerfile | Use when |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Ubuntu | `ubuntu:latest` | `apt-get` | `-e ubuntu` | `Dockerfile` | Default. PPA support, widest binary compatibility. |
| Debian | `debian:stable-slim` | `apt-get` | `-e debian` | `Dockerfile.debian` | Same ecosystem, smaller and slower-moving. |
| Alpine | `alpine:latest` | `apk` | `-e alpine` | `Dockerfile.alpine` | Smallest footprint; musl libc caveat below. |
| Arch | `archlinux:latest` | `pacman` | `-e arch` | `Dockerfile.arch` | Rolling releases, newest upstream packages. |

Each engine has a published prebuilt image and can be built locally — see [Images](images.md).

## What is installed

**Runtimes and compilers**

- Python: `uv`/`uvx`, `pipx`, `python3-venv`
- Rust: `rustup` minimal profile (`cargo`, `rustc`)
- Go: Go 1.24 toolchain (`GO_VERSION=1.24.2` build arg)
- JavaScript: Node.js from the NodeSource **current** channel, plus Bun
- C/C++: `build-essential` (Debian/Ubuntu), `base-devel` (Arch), `build-base` (Alpine), with `cmake`, `make`, `gdb`

**Editors and Git**

- `helix` (with runtime assets), `micro`, `lazygit`, `tmux`

**CLI**

- `bat`, `eza`, `zoxide`, `fd`, `ripgrep`, `jq`, `fzf`, `nnn`, `htop`, `btop`, `fastfetch`, `figlet`, `fortune`
- `nmap`, `lsof`, `ncdu`, `tree`, `sysstat`, `inxi`, `zip`/`7z`

**Agent stack**

- `opencode` (v2), `agy`/`antigravity`, `rtk` — all kept current by `harness-update` ([Images](images.md#harnesses-are-never-pinned))
- HeLa MCP runtime: one `hela-runtime` endpoint exposing the selected profile (default `dev-workspace`, 8 cells / 234 tools), with per-cell launchers in `/usr/local/bin` (`mcp-mitosis` … `mcp-plastid`, `mcp-runtime`)
- Google Conductor at `/opt/conductor`, linked into `~/.agents/plugins` and `~/.gemini/config/plugins`

**Shell experience**

- Oh-My-Bash with theme and Git prompt
- Alias-Hub (`~/alias-hub`) with categorized aliases
- fastfetch config plus `fetch`, `rfetch`, `ascii` helpers (random ASCII banners)

## Version policy

Two kinds of version, deliberately different:

- **Image toolchain** — pinned where it matters (Go 1.24.2, Helix 25.01.1, lazygit 0.61.1 as build args), floating where upstream's "current" is the sane default (Node.js). Rebuild the image to move those pins.
- **Agent harnesses** — never pinned. `harness-update` installs the latest release of `opencode`, `agy` and `rtk` at build, at container start when stale, and on demand.

Ask an engine what it actually has:

```bash
cat /etc/os-release
node -v && go version && rustc --version && python3 -V
opencode --version && agy --version && rtk --version
```

## Engine caveats

- **Alpine uses musl.** Some prebuilt Linux binaries (including glibc-only release assets from upstream projects) will not run inside it. If a tool fails with "not found" despite being executable, that is almost always the cause — use Debian or Ubuntu for that workload.
- **Arch moves.** A rebuild can pull different package versions than yesterday. That is the point, but it makes it the worst choice for reproducible CI.
- **PPAs exist only on Ubuntu.** `add-apt-repository` in other engines fails; use the distro's repositories or a Dockerfile.
- **All engines share the host kernel.** No engine gives you a different kernel; see [Ghost vs VM](comparison-vs-vm.md).

## Choosing the HeLa profile

The images install the HeLa runtime in runtime mode (`node setup.mjs --profile <id> --mode runtime`), which serves every cell of the profile through one MCP endpoint. The default is `dev-workspace`; switch it at build time:

```bash
HELA_PROFILE=headless-server ./start.sh -e debian -m single --build
HELA_PROFILE=minimal ./start.sh -e alpine -m single --build
```

The ecosystem snapshot is pinned (`--snapshot v1.9.5`, `HELA_SNAPSHOT` build arg) because v1.9.6 fails the installer's catalog verification: its phenotype pin reports a mismatched version. Bump the pin once an upstream snapshot verifies cleanly.

`minimal` (3 cells) is the lightest, `headless-server` (7, no browser) is the CI default elsewhere, `dev-workspace` (8, includes browser + design) is the sandbox default. Check the installed profile inside the sandbox:

```bash
node /opt/hela-src/setup.mjs doctor --prefix /opt/hela
```

## Adding a package or changing an engine

Permanent changes belong in the engine's Dockerfile, then rebuild:

```bash
# edit Dockerfile.debian, then
./start.sh -e debian -m single --build
```

Ad-hoc changes inside a running sandbox (`apt install …`) disappear when the container is recreated. That is intentional: the image stays reproducible, and your data stays in `mounts/`. See [Contributing](contributing.md) for the full loop and the test list.
