# Homepage

Homepage is the central QuesadaLab dashboard. It is available internally at
`http://homepage.lab` and remotely at `https://cloud.ithakidev.com` behind
Cloudflare Access.

## Configuration ownership

The managed configuration lives in `config/homepage/` and is synchronized to
`/opt/quesadalab/config/homepage/` by `deploy.sh`. The Homepage container mounts
that live managed directory at `/app/config`.

Runtime logs may be created below the live configuration directory. They are
not copied back into the repository.

## Secrets

Widget credentials belong only in `/opt/quesadalab/stacks/homepage/.env`.
Homepage substitutes variables beginning with `HOMEPAGE_VAR_` inside its YAML
configuration. The required variable names are documented in
`stacks/homepage/.env.example`; real values must never be committed.

The Proxmox widget uses an API token identifier as its username and the token
secret as its password. The AdGuard widget uses the dedicated dashboard
credentials already present in the live environment.

## Service groups

- **Servicios esenciales** contains services intended to remain online.
- **Hermes Agent** contains the agent and its messaging entry points.
- **Infraestructura** contains administrative interfaces.
- **Bajo demanda** contains intentionally stopped workloads.
- **Diagnóstico** contains low-level troubleshooting services.

Stopped Docker containers remain defined in Homepage so their intentional
offline state is visible through the Docker integration.

## Deployment

From `/opt/quesadalab-repo` on `docker01`:

```bash
./deploy.sh homepage --dry-run
./deploy.sh homepage
```

Before the first managed deployment, preserve the legacy configuration from
`/opt/quesadalab/data/homepage/config`. The deployment runbook supplied with
the change performs this migration backup before switching the bind mount.
