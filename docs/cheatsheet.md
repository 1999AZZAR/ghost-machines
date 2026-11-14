# Cheatsheet

One page, every command you need day to day.

## Start

```bash
./start.sh                                   # interactive
./start.sh --prebuilt ubuntu -m single       # GHCR image, no build
./start.sh -e debian -m dual --build         # local build, 2 machines
./start.sh -e alpine -m power -p 2225        # custom port, heavy profile
make prebuilt ENGINE=debian MODE=single
```

## Connect

```bash
ssh -p 2223 developer@localhost              # password: ghost
ssh -p 2224 developer@localhost              # dual, second machine
docker exec -it ghost-machine-single bash     # no SSH
source aliases.sh && ghost-ssh single         # helper
ssh -p 2223 -L 3000:localhost:3000 developer@localhost   # reach a dev server
```

## Inspect

```bash
./start.sh status
./start.sh logs
docker inspect -f '{{.Config.Image}}' ghost-machine-single
docker stats --no-stream
docker compose --profile dual config
```

## Stop / restart / remove

```bash
./start.sh restart                            # in place
docker compose --profile dual stop            # pause, container kept
docker compose --profile dual start           # resume
./start.sh stop                               # remove containers + network
./clean.sh -a -y                              # + images, keeps mounts/
./clean.sh --nuke --hard -y                   # + mounts/ (destructive)
```

## Backup / restore

```bash
make snapshot
./snapshot.sh -o backup.tar.gz
./restore.sh backup.tar.gz
./restore.sh -y backup.tar.gz
```

## Agents

```bash
harness-update                                # inside sandbox: refresh all
harness-update opencode                       # one harness
./start.sh --update-harness                   # from host
opencode --version && agy --version && rtk --version
```

## Tenants

```bash
./tenant.sh add alice --prebuilt --engine debian --cpu 2 --mem 4G
./tenant.sh list
./tenant.sh stats
./tenant.sh stop alice && ./tenant.sh start alice
./tenant.sh snapshot alice
./tenant.sh delete alice --archive -y
```

## Images

```bash
./start.sh --prebuilt debian -m single --pull           # newest
./start.sh --image ghcr.io/1999azzar/ghost-machine-ubuntu:v2.1.0 -m single   # pinned
make build-debian && ./start.sh -e debian -m single
docker images | grep -E 'ghost-machine|template'
```

## Config

```bash
cp .env.example .env       # then edit
$EDITOR .env
./start.sh stop && ./start.sh    # recreate after changing ports/tokens/image
```

| Variable | Default |
| :--- | :--- |
| `G1_PORT` / `G2_PORT` | 2223 / 2224 |
| `GHOST_USER` | `developer` |
| `SSH_PASSWORD_AUTH` | `true` |
| `GHOST_IMAGE` | engine default |
| `GHOST_HARNESS_UPDATE` | `latest` |
| `HARNESS_UPDATE_INTERVAL_HOURS` | 24 |

## Develop

```bash
make lint      # shellcheck + bash -n + compose
make test      # 8 suites, includes docs checks
make docs      # regenerate the docs site
```

## Fixes for the usual three

```bash
# port busy
./start.sh -p 2225
# host key changed
ssh-keygen -R "[localhost]:2223"
# mounts owned by the wrong user
./start.sh stop && ./start.sh
```
