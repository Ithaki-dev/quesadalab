# Jellyfin restore

The restore replaces Jellyfin configuration and application state. It never
modifies `/srv/jellyfin-media`, so the media libraries must already be present
at their normal paths.

## Preconditions

- Run on `docker01` as root.
- Verify the desired backup set and current media mount.
- Confirm Jellyfin is healthy before establishing the restore baseline.
- Stop active library maintenance and user sessions.

```bash
backup_set=/path/to/YYYY-MM-DD_HH-MM-SS
(cd "$backup_set" && sha256sum --check SHA256SUMS)
findmnt /srv/jellyfin-media
docker inspect jellyfin --format '{{.State.Health.Status}}'
```

## Restore

```bash
/opt/quesadalab/scripts/restore-jellyfin.sh "$backup_set"
```

The script requires the exact confirmation `RESTORE-JELLYFIN`. It stops the
container, saves the current configuration and stack beneath
`/opt/quesadalab/backups/jellyfin-restore-rollback`, restores the selected
archive, reapplies ownership, starts Jellyfin and waits for a healthy state.

## Validation

```bash
docker inspect jellyfin \
  --format 'status={{.State.Status}} health={{.State.Health.Status}}'

curl --silent --show-error --output /dev/null \
  --write-out 'Jellyfin HTTP %{http_code}\n' \
  https://jellyfin.lab/health
```

Validate administrator login, libraries, playback, subtitles and one forced
VA-API transcode before deleting the rollback directory.
