# Status Page

## Objetivo

La Status Page de Uptime Kuma proporciona una vista privada del estado de los
servicios de QuesadaLab.

## URL

```text
http://status.lab
```

## Servicios monitorizados

### Infraestructura

- Proxmox VE
- Docker VM `docker01`
- Hermes VM `agent01`

### Red

- OpenWrt
- AdGuard Home
- Internet

### Críticos

- Traefik
- Cloudflare Tunnel
- Vaultwarden
- OmniRoute

### Permanentes no críticos

- Homepage
- Portainer
- Uptime Kuma
- Nextcloud
- Node Exporter
- Prometheus

### Bajo demanda

- Immich
- Jellyfin
- Grafana
- cAdvisor

### En retirada

- Home Assistant

## Configuración

Cada monitor se actualiza normalmente cada 60 segundos.

Home Assistant se supervisa mediante `https://homeassistant.lab/` solo cuando VM
300 está encendida para recuperación o migración. El monitor debe permanecer
pausado mientras la VM esté en retirada y apagada.

Los monitores de Immich, Jellyfin, Grafana y cAdvisor deben entrar en
mantenimiento cuando sus stacks estén detenidos deliberadamente.

Prometheus es permanente. Si cAdvisor está apagado, el target `cadvisor:8080`
puede aparecer `DOWN` en Prometheus; eso representa el ciclo de vida bajo
demanda de cAdvisor, no una falla de Prometheus.

## Buenas prácticas

- Usar HTTP(S) para servicios web.
- Usar Ping para dispositivos de red.
- Mantener grupos organizados por criticidad.
- Documentar cada nuevo monitor incorporado.
- No tratar servicios bajo demanda apagados como incidentes activos.
