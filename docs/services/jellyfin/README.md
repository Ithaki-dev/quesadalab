# Jellyfin

Jellyfin is the internal media server for QuesadaLab. It is exposed only as
`https://jellyfin.lab` through Traefik and does not publish its native ports on
the Docker host.

## Design

- Official image pinned to a reviewed release.
- Dedicated 200 GiB ext4 disk mounted at `/srv/jellyfin-media`.
- Application configuration stored at `/opt/quesadalab/data/jellyfin/config`.
- Media mounted read-only inside the container.
- Cache and transcodes stored on the dedicated media disk.
- Intel HD 4600 passed through to `docker01` and exposed as
  `/dev/dri/renderD128`.
- VA-API with the legacy `i965` driver; Haswell does not support Jellyfin QSV.
- Media files are deliberately excluded from backup. Only configuration and
  application state will be protected by the later backup phase.

The HD 4600 accelerates H.264, MPEG-2, VC-1, and JPEG. It does not provide
modern HEVC, VP9, AV1, or HDR tone-mapping acceleration. Prefer Direct Play
for those formats and avoid unnecessary 4K transcoding.

## Host prerequisites

The live host must provide:

```text
/dev/dri/renderD128
/opt/quesadalab/data/jellyfin/config
/srv/jellyfin-media/cache
/srv/jellyfin-media/transcodes
/srv/jellyfin-media/movies
/srv/jellyfin-media/series
/srv/jellyfin-media/music
/srv/jellyfin-media/home-videos
```

Confirm VA-API before deployment:

```bash
LIBVA_DRIVER_NAME=i965 \
  vainfo --display drm --device /dev/dri/renderD128
```

## Live environment

Copy `.env.example` to `/opt/quesadalab/stacks/jellyfin/.env` and adjust the
UID/GID values to the live host. The environment file is runtime-only and must
not be committed.

The configuration, cache, transcode, and media directories must be owned by
the configured Jellyfin UID/GID. The render and video supplemental group IDs
must match `getent group render` and `getent group video` on `docker01`.

## Deployment

Validate and simulate first:

```bash
./scripts/validate.sh
./deploy.sh jellyfin --dry-run
```

Then deploy after approval:

```bash
./deploy.sh jellyfin --pull
```

## Initial configuration

Open `https://jellyfin.lab`, create the initial administrator, and add these
libraries:

| Library | Container path |
|---|---|
| Movies | `/media/movies` |
| Series | `/media/series` |
| Music | `/media/music` |
| Home videos | `/media/home-videos` |

In **Dashboard > Playback > Transcoding**:

1. Select `Video Acceleration API (VAAPI)`.
2. Set the device to `/dev/dri/renderD128`.
3. Enable hardware decoding only for H.264, MPEG-2, VC-1, and JPEG.
4. Enable hardware encoding.
5. Leave HEVC, VP9, AV1, tone mapping, and Intel low-power encoders disabled.
6. Set the transcode path to `/transcodes`.

## Validation

```bash
docker inspect jellyfin \
  --format 'status={{.State.Status}} health={{.State.Health.Status}}'

curl --silent --show-error --output /dev/null \
  --write-out 'Jellyfin HTTP %{http_code}\n' \
  https://jellyfin.lab/health

docker exec jellyfin \
  /usr/lib/jellyfin-ffmpeg/vainfo \
    --display drm \
    --device /dev/dri/renderD128
```

For the final acceleration test, force an H.264 transcode from a client and
confirm `h264_vaapi` in the active FFmpeg log. Direct Play correctly produces
no transcoding process.

## Backup boundary

Back up the Jellyfin configuration and database under
`/opt/quesadalab/data/jellyfin/config`. Do not back up any content under
`/srv/jellyfin-media`, including movies, series, music, home videos, cache, or
transcodes.
