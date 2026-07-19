# Jellyfin configuration backup

This procedure protects Jellyfin application state without duplicating the
replaceable media library.

## Scope

Included:

- `/opt/quesadalab/data/jellyfin/config`
- `/opt/quesadalab/stacks/jellyfin`, including the live `.env`
- Jellyfin SQLite database, users, plugins, metadata, artwork and settings

Excluded:

- `/srv/jellyfin-media/movies`
- `/srv/jellyfin-media/series`
- `/srv/jellyfin-media/music`
- `/srv/jellyfin-media/home-videos`
- `/srv/jellyfin-media/cache`
- `/srv/jellyfin-media/transcodes`

The local job runs at 02:30 and retains three sets. It briefly stops only the
Jellyfin container to obtain a consistent SQLite copy, then starts it and waits
for its health check. The Proxmox pull runs at 02:45 and retains seven USB sets.

## Install on docker01

```bash
install -o root -g root -m 0750 \
  scripts/backup-jellyfin.sh \
  scripts/restore-jellyfin.sh \
  /opt/quesadalab/scripts/

install -o root -g root -m 0644 \
  systemd/backup-jellyfin.service \
  systemd/backup-jellyfin.timer \
  /etc/systemd/system/

systemctl daemon-reload
```

Keep the timer disabled until a manual backup succeeds:

```bash
systemctl start backup-jellyfin.service
journalctl -u backup-jellyfin.service -n 80 --no-pager
```

Verify the latest set:

```bash
latest="$(find /opt/quesadalab/backups/jellyfin \
  -mindepth 1 -maxdepth 1 -type d -name '????-??-??_??-??-??' \
  -printf '%p\n' | sort | tail -n 1)"

(cd "$latest" && sha256sum --check SHA256SUMS)
tar -tzf "$latest/configuration.tar.gz" >/dev/null
docker inspect jellyfin --format '{{.State.Health.Status}}'
```

## Configure restricted USB pull

On Proxmox, create a dedicated Ed25519 key. Add its public key to docker01
with a forced read-only rsync command:

```text
restrict,command="/usr/bin/rrsync -ro /opt/quesadalab/backups/jellyfin" ssh-ed25519 PUBLIC_KEY quesadalab-jellyfin-backup-pull
```

Install `scripts/pull-jellyfin-backups.sh` as
`/usr/local/sbin/pull-jellyfin-backups.sh`, and install its service and timer
under `/etc/systemd/system`. The private key must be stored as
`/root/.ssh/quesadalab-jellyfin-backup` with mode `0600`.

Run and validate the service manually before enabling automation:

```bash
systemctl start pull-jellyfin-backups.service
journalctl -u pull-jellyfin-backups.service -n 80 --no-pager

latest="$(find /mnt/quesadalab-backup/jellyfin \
  -mindepth 1 -maxdepth 1 -type d -name '????-??-??_??-??-??' \
  -printf '%p\n' | sort | tail -n 1)"
(cd "$latest" && sha256sum --check SHA256SUMS)
```

After both manual tests pass:

```bash
# docker01
systemctl enable --now backup-jellyfin.timer

# Proxmox
systemctl enable --now pull-jellyfin-backups.timer
```
