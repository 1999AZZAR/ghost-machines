# Contributing

## Repo layout

```text
start.sh            launch: engine, mode, image, lifecycle verbs
clean.sh            four cleanup levels
tenant.sh           multi-tenant provisioning
snapshot.sh         backup with cache exclusions + SHA-256
restore.sh          verified, atomic restore
setup-host.sh       host prerequisites (LXCFS, Docker)
entrypoint.sh       first boot inside the container
harness-update.sh   installs/refreshes opencode, agy, rtk
aliases.sh          ghost-* shell helpers
Dockerfile*         four engines (ubuntu, debian, alpine, arch)
docker-compose.yml  main topology; templates/ holds the tenant topology
tests/              bash test suites, run_all.sh runner
docs/               markdown source for the docs site
docs/site/          generated pages (do not edit by hand)
tools/build_site.py docs/*.md → docs/site/pages/*.html
```

## Dev loop

```bash
make lint                    # shellcheck + bash -n + compose config
make test                    # full suite (9 suites)
make docs                    # regenerate the docs site
./start.sh -e debian -m single --build
```

Rules of thumb:

- Everything must pass `bash -n` **and** `shellcheck -e SC1091 -e SC2034`.
- Scripts are `set -e` and fail loudly; no silent `|| true` around anything that matters.
- New shell behaviour needs a line in the matching test suite — the suites assert source properties, not just syntax.
- Container behaviour belongs in `entrypoint.sh` or a Dockerfile, never in manual instructions.

## Test suites

`tests/run_all.sh` runs, in order:

| Suite | Asserts |
| :--- | :--- |
| `test_lint.sh` | shellcheck, `bash -n` on every script, Dockerfile structure, compose schema |
| `test_m1_security.sh` | UID/GID sync, key permissions, entrypoint auth handling |
| `test_m2_engine_optimization.sh` | layer cleanup and parity across the four Dockerfiles |
| `test_m3_cli_orchestration.sh` | flag matrix, image resolution (prebuilt vs build), lifecycle verbs |
| `test_m4_snapshot_restore.sh` | cache exclusions, SHA-256 verification, atomic rollback |
| `test_m5_hela_mcp.sh` | MCP wrappers, harness wiring, Conductor links |
| `test_m5_toolchain.sh` | `uv`, `pipx`, Rust, PATH setup |
| `test_m6_multi_tenant.sh` | tenant provisioning, registry, isolation |
| `test_docs.sh` | links/anchors, doc facts vs code, fenced examples, site freshness |

CI (`.github/workflows/ci.yml`) runs the full suite on `ubuntu-latest` (`linux/amd64`), then a build smoke test per engine. Multi-arch images are built by `publish.yml` with QEMU targetting `linux/amd64` and `linux/arm64` — CI itself is not a multi-arch runner matrix.

## Documentation rules

`docs/*.md` is the source; `docs/site/pages/*.html` is generated. Never edit generated pages.

```bash
make docs                       # regenerate
python3 tools/build_site.py --check   # what CI runs; fails if stale
```

Requires the `markdown` package:

```bash
python3 -m pip install --user markdown
# or
nix shell nixpkgs#python3Packages.markdown -c python3 tools/build_site.py
```

Writing rules:

- **Command first, prose second.** Every section opens with something runnable.
- **No undated claims.** If you state a size, port, version or count, derive it from the code — `test_docs.sh` greps docs against `docker-compose.yml`, `.env.example`, `tests/run_all.sh` and the Dockerfiles, and will fail on drift.
- **No duplicate sources of truth.** Reference another page instead of copying its table.
- **State the audience** for anything that differs between a laptop and a shared host.

## Documentation deployment

Push to `master` touching `docs/**` or `tools/**`, and `.github/workflows/pages.yml`:

1. installs `markdown`, runs `tools/build_site.py` (regenerates `docs/site`),
2. runs `tests/test_docs.sh` (links, examples, facts, freshness) — a failure blocks deployment,
3. force-pushes the rendered `docs/site` to the `gh-pages` branch.

GitHub Pages serves that branch at <https://ghost.glassgallery.my.id>. Nothing is committed to `gh-pages` by hand, and the branch holds only the generated artifact.

`docs/site/site.json` is the single source for the public identity:

| Key | Effect |
| :--- | :--- |
| `base_url` | canonical URLs in `sitemap.xml` and the `Sitemap:` line in `robots.txt` |
| `cname` | written to `docs/site/CNAME`, which GitHub Pages reads for the custom domain |

Change the domain in one place and sitemap, robots and CNAME stay consistent.

## Release process

1. Merge to `master` with the suite green.
2. Tag: `git tag v2.2.0 && git push origin v2.2.0`.
3. `.github/workflows/publish.yml` builds all four engines for `linux/amd64` + `linux/arm64` and pushes to GHCR with three tags per package: `latest`, the release tag (`v2.2.0`), and `latest-<short-sha>`.
4. Consumers upgrade with `--pull` and roll back by pinning the previous `vX.Y.Z`.

Tagging is the only release step; there is no changelog file, the commit history is the changelog.

## Adding an engine

1. Copy the closest Dockerfile (e.g. `Dockerfile.debian` → `Dockerfile.fedora`) and adapt the package manager.
2. `start.sh` — add the engine case (Dockerfile + `<engine>-template:latest`), and the GHCR mapping used by `--prebuilt`.
3. `clean.sh` — add the local tag to the Level 3/4 removal list.
4. `tenant.sh` — add the engine to the Dockerfile mapping.
5. `tests/` — add the Dockerfile to the loops in `test_m2_engine_optimization.sh` and `test_lint.sh`.
6. `.github/workflows/publish.yml` — add the matrix entry (image name + Dockerfile).
7. Docs — `docs/engines.md` table, `docs/images.md` size/tag table.

`test_docs.sh` checks that every engine in the docs table has a Dockerfile, so a missed step fails CI.

## Style

- Shell: `set -e`, quoted expansions, `local` in functions, `printf` over `echo` for anything non-constant, explicit exit codes.
- Comments explain *why*, not *what*; no commented-out code.
- Commit messages: `type(scope): summary` with a body that says what breaks and why (`fix`, `feat`, `docs`, `refactor`, `chore`).
- Keep dependencies to what the base images already ship; this project avoids extra runtime services on the host.
