# OmniRoute backup and restore

OmniRoute backups are confidential because application state can contain
provider credentials, routing policy and locally issued API keys.

## Backup

Run on `docker01`. Stop the stack to obtain a consistent application and Redis
snapshot:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/omniroute \
  --env-file /opt/quesadalab/stacks/omniroute/.env \
  --file /opt/quesadalab/stacks/omniroute/docker-compose.yml \
  stop --timeout 60

timestamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="/opt/quesadalab/backups/omniroute/${timestamp}"

install -d -o root -g root -m 0700 "$backup_dir"

tar \
  --create \
  --gzip \
  --file "$backup_dir/omniroute-state.tar.gz" \
  --directory /opt/quesadalab/data \
  omniroute \
  omniroute-redis

install -o root -g root -m 0600 \
  /opt/quesadalab/stacks/omniroute/.env \
  "$backup_dir/omniroute.env"

sha256sum \
  "$backup_dir/omniroute-state.tar.gz" \
  "$backup_dir/omniroute.env" \
  > "$backup_dir/SHA256SUMS"

(cd "$backup_dir" && sha256sum --check SHA256SUMS)
```

Move the completed set to encrypted or physically controlled backup storage.
Do not expose it through Homepage, Traefik or Cloudflare.

## Restore

Keep the stack stopped. Verify hashes before replacing state:

```bash
restore_dir="/path/to/verified/backup"
(cd "$restore_dir" && sha256sum --check SHA256SUMS)
```

Preserve the current state before proceeding. Then restore with ownership and
permissions:

```bash
tar \
  --extract \
  --gzip \
  --file "$restore_dir/omniroute-state.tar.gz" \
  --directory /opt/quesadalab/data

install -o root -g root -m 0600 \
  "$restore_dir/omniroute.env" \
  /opt/quesadalab/stacks/omniroute/.env

chown -R 1000:1000 /opt/quesadalab/data/omniroute
chown -R 999:999 /opt/quesadalab/data/omniroute-redis
```

Rebuild the pinned image with `scripts/prepare-omniroute-image.sh`, deploy the
stack, validate HTTPS and test a dedicated low-risk provider credential before
reconnecting any client.
