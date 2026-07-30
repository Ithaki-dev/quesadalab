# OmniRoute

OmniRoute is an experimental, on-demand AI gateway for testing model routing,
provider credentials and OpenAI-compatible clients. It is not part of the
always-on QuesadaLab control plane.

## Production boundary

| Item | Value |
| --- | --- |
| Host | `docker01` |
| Internal URL | `https://omniroute.lab` |
| Runtime | Docker Compose |
| Source release | `v3.8.49` |
| Annotated tag object | `bbb3b6eab72911d4fd7e6be9315edc983e5c1a6b` |
| Reviewed commit | `c9d4a45f1883d7daf150bbff631f3e83b41aa5b4` |
| Image | Official AMD64 image pinned by repository digest |
| State | `/opt/quesadalab/data/omniroute` |
| Redis state | `/opt/quesadalab/data/omniroute-redis` |
| Exposure | LAN only through Traefik |
| Normal state | Stopped |

Hermes remains connected directly to OpenRouter until OmniRoute has passed
functional and stability tests. Do not add a Cloudflare Tunnel route for this
service.

## Security model

- OmniRoute and Redis publish no host ports.
- Redis is connected only to the internal `omniroute-backend` network.
- The web/API endpoint is protected by Traefik's `lan-only` and
  `security-headers` middleware.
- The reviewed image runs as the non-root `node` user with all Linux
  capabilities dropped by Compose.
- JWT, API-key, storage-encryption and bootstrap credentials live only in the
  deployed `.env`, never in Git.
- All OpenAI-compatible `/v1` requests require a dedicated OmniRoute API key.
- Backups contain provider credentials and must be treated as confidential.

## Resource profile

The production limit is 1536 MiB and 1.5 CPU for OmniRoute, plus 128 MiB and
0.5 CPU for Redis. `OMNIROUTE_MEMORY_MB=768` limits the Node.js heap and leaves
approximately 768 MiB for native allocations and runtime overhead. The
application limit was increased after Docker recorded an OOM termination while
testing release 3.8.49 with the former 1 GiB limit.

## Release 3.8.49 provider limitation

The zero-credential OpenCode routes advertised by upstream are not considered
production-ready in this deployment. Direct `oc/...` requests can fail while
attempting to connect to `0.0.0.0:443`. An `auto/best-free` success does not by
itself validate zero-credential operation because the combo can fall back to a
configured provider such as OpenRouter.

Keep Hermes on its validated direct provider path until both a direct
zero-credential route and the intended `auto/...` route pass from `agent01`.

## Prepare the image

After pulling the repository on `docker01`:

```bash
cd /opt/quesadalab-repo
sudo ./scripts/prepare-omniroute-image.sh
```

The script downloads
`docker.io/diegosouzapw/omniroute@sha256:92c768c56e2de32c51a0621ef182835018b00b288c9bb235c5c5e4514658c1a1`.
It verifies the immutable repository digest, Linux/AMD64 platform, non-root
`node` user and upstream source label. It does not compile source or start a
container.

## Prepare runtime state and secrets

```bash
sudo install -d -o 1000 -g 1000 -m 0700 \
  /opt/quesadalab/data/omniroute

sudo install -d -o 999 -g 999 -m 0700 \
  /opt/quesadalab/data/omniroute-redis

cd /opt/quesadalab/stacks/omniroute
sudo install -o root -g root -m 0600 \
  .env.example .env
```

Replace every `replace-with-...` value. Generate the three 64-character
secrets independently:

```bash
openssl rand -hex 32
```

Use a long, unique `INITIAL_PASSWORD`. Do not paste the resulting `.env` into
issues, chat, logs or commits.

## Deploy and validate

Create the AdGuard record `omniroute.lab -> 192.168.1.30`, then:

```bash
cd /opt/quesadalab-repo
sudo ./deploy.sh omniroute

docker inspect omniroute omniroute-redis \
  --format 'name={{.Name}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'

curl --silent --show-error --output /dev/null \
  --write-out 'OmniRoute HTTPS %{http_code}\n' \
  https://omniroute.lab/
```

Complete the bootstrap login, change the initial password if the UI offers that
control, and add only a dedicated low-limit provider credential. Create
separate, least-privilege OmniRoute client keys for each consumer; never expose
the provider credential directly to Hermes or other clients.

## Operate on demand

Start:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/omniroute \
  --env-file /opt/quesadalab/stacks/omniroute/.env \
  --file /opt/quesadalab/stacks/omniroute/docker-compose.yml \
  start
```

Stop:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/omniroute \
  --env-file /opt/quesadalab/stacks/omniroute/.env \
  --file /opt/quesadalab/stacks/omniroute/docker-compose.yml \
  stop --timeout 60
```

Use `stop`, not `down --volumes`. The stack uses `restart: "no"` and is
intentionally excluded from `deploy.sh all`.

See [OmniRoute backup and restore](../../runbooks/omniroute-backup-restore.md)
before upgrades or provider changes.
