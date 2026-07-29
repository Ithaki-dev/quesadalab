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
| Source release | `v3.8.48` |
| Annotated tag object | `4f00f84b5a12f90fca2f1d72a60404cf6f5bf059` |
| Reviewed commit | `7ee5bbc64dbb03e967521227f2afffeb7c9dad1e` |
| Image | Locally built `runner-base` |
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
- The application runs as the non-root `node` user with all Linux capabilities
  dropped.
- JWT, API-key, storage-encryption and bootstrap credentials live only in the
  deployed `.env`, never in Git.
- Backups contain provider credentials and must be treated as confidential.

## Resource profile

The initial limit is 1 GiB and 1.5 CPU for OmniRoute, plus 128 MiB and 0.5 CPU
for Redis. `OMNIROUTE_MEMORY_MB=768` limits the Node.js heap. Increase the
application limit to 1536 MiB only after observing an out-of-memory event or
sustained memory pressure.

## Prepare the image

After pulling the repository on `docker01`:

```bash
cd /opt/quesadalab-repo
sudo ./scripts/prepare-omniroute-image.sh
```

The script clones the immutable upstream tag, verifies both the annotated tag
object and its target commit, and builds only the `runner-base` target. An
existing image is reused only when its revision label matches the reviewed
commit.

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
control, and add only a dedicated low-limit provider credential.

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
