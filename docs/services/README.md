# Services

This directory contains the service documentation for QuesadaLab.

Older services use a multi-file structure while newer services keep a single
README. Both forms are valid:

```
README.md
01-design.md
02-installation.md
03-configuration.md
04-validation.md
```

## Current services

| Service | Runtime | Documentation |
|---|---|---|
| Proxmox VE | Always on | [`proxmox`](proxmox/README.md) |
| AdGuard Home | Always on | [`adguard-home`](adguard-home/01-design.md) |
| Docker Engine | Always on | [`docker-engine`](docker-engine/README.md) |
| Portainer | Always on | [`portainer`](portainer/README.md) |
| Traefik | Always on | [`traefik`](traefik/README.md) |
| Cloudflare Tunnel | Always on | [`cloudflared`](cloudflared/README.md) |
| Homepage | Always on | [`homepage`](homepage/README.md) |
| Uptime Kuma | Always on | [`uptime-kuma`](uptime-kuma/README.md) |
| Node Exporter | Always on | [`node-exporter`](node-exporter/README.md) |
| Nextcloud | Always on | [`nextcloud`](nextcloud/README.md) |
| Vaultwarden | Always on | [`vaultwarden`](vaultwarden/README.md) |
| Hermes Agent | Always on | [`hermes-agent`](hermes-agent/README.md) |
| Home Assistant | On demand | [`home-assistant`](home-assistant/README.md) |
| Immich | On demand | [`immich`](immich/README.md) |
| Jellyfin | On demand | [`jellyfin`](jellyfin/README.md) |
| Prometheus | On demand | [`prometheus`](prometheus/README.md) |
| Grafana | On demand | [`grafana`](grafana/README.md) |
| cAdvisor | On demand | [`cadvisor`](cadvisor/README.md) |

Planned services are not listed as deployed until their implementation and
validation are complete.
