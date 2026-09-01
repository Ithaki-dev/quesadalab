# OmniRoute

OmniRoute is the internal AI gateway used by QuesadaLab for OpenAI-compatible
clients such as Hermes. It runs on `docker01` and is now part of the critical
always-on service set.

## Production boundary

| Item | Value |
|---|---|
| Host | `docker01` |
| Internal URL | `https://omniroute.lab` |
| Runtime | Docker Compose |
| Source release | `v3.8.50` |
| Image | Official AMD64 image pinned by repository digest |
| Image digest | `sha256:085c57adf499a8aaa9f35ccde95c0df9c11bd9ecd18d6c9edbf3b68b8079ba9d` |
| State | `/opt/quesadalab/data/omniroute` |
| Redis state | `/opt/quesadalab/data/omniroute-redis` |
| Exposure | LAN only through Traefik |
| Normal state | Running |
| Restart policy | `unless-stopped` |

Do not add a Cloudflare Tunnel route for this service unless a separate review
approves the exposure model.

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
- Backups contain provider credentials and client API keys and must be treated
  as confidential.

## Resource profile

The repository keeps the current container limits unchanged:

- OmniRoute: 1536 MiB, 1.5 CPU, PID limit 256.
- Redis: 128 MiB, 0.5 CPU, PID limit 128.
- `OMNIROUTE_MEMORY_MB=768` controls the Node.js heap in the live `.env`.

Do not increase CPU, memory, PID limits, healthchecks, networks, volumes or
security settings without a separate capacity review. OmniRoute previously hit
OOM during testing, so upgrades should include post-deploy memory observation.

## Current provider notes

Hermes and other clients should use a dedicated OmniRoute client API key. Do not
expose provider credentials directly to clients.

Validated behavior after moving to `v3.8.50`:

- `auto/best-free` works with low token limits.
- `oc/big-pickle` works with low token limits.
- Plain `auto` can route to OpenRouter and fail if the request asks for too many
  output tokens. Keep Hermes on a validated model such as `auto/best-free` until
  token defaults are reviewed.
- Kiro requires an active provider credential in OmniRoute. If Kiro reports
  `No active credentials`, reconnect it in the OmniRoute dashboard before using
  it in routing pools.

OpenRouter is an external provider. OmniRoute is the internal gateway. Do not
use the two names interchangeably in documentation or operations.

## Prepare the image

After pulling the repository on `docker01`:

```bash
cd /opt/quesadalab-repo
sudo ./scripts/prepare-omniroute-image.sh
```

The script downloads and validates:

```text
docker.io/diegosouzapw/omniroute@sha256:085c57adf499a8aaa9f35ccde95c0df9c11bd9ecd18d6c9edbf3b68b8079ba9d
```

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

Replace every `replace-with-...` value. Generate independent 64-character
secrets with:

```bash
openssl rand -hex 32
```

Use a long, unique `INITIAL_PASSWORD`. Do not paste the resulting `.env` into
issues, chat, logs or commits.

## Deploy and validate

Create or verify the AdGuard record `omniroute.lab -> 192.168.1.30`, then:

```bash
cd /opt/quesadalab-repo
sudo ./deploy.sh omniroute

docker inspect omniroute omniroute-redis \
  --format 'name={{.Name}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} restart={{.HostConfig.RestartPolicy.Name}}'

curl --silent --show-error --output /dev/null \
  --write-out 'OmniRoute HTTPS %{http_code}\n' \
  https://omniroute.lab/
```

Complete bootstrap login, change the initial password if the UI offers that
control, and create least-privilege client keys for consumers.

## Operations

OmniRoute is persistent and should be started by Compose with
`restart: unless-stopped`.

Start or recreate:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/omniroute \
  --env-file /opt/quesadalab/stacks/omniroute/.env \
  --file /opt/quesadalab/stacks/omniroute/docker-compose.yml \
  up -d
```

Stop only for approved maintenance:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/omniroute \
  --env-file /opt/quesadalab/stacks/omniroute/.env \
  --file /opt/quesadalab/stacks/omniroute/docker-compose.yml \
  stop --timeout 60
```

Use `stop`, not `down --volumes`.

See [OmniRoute backup and restore](../../runbooks/omniroute-backup-restore.md)
before upgrades or provider changes.
