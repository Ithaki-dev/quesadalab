# Proxmox QuesadaLab

## Descripción

QuesadaLab es un laboratorio de infraestructura y virtualización construido sobre Proxmox VE con el objetivo de aprender, documentar y administrar una infraestructura doméstica basada en tecnologías Open Source.

Este proyecto es desarrollado por Robert Quesada junto con su padre como una iniciativa de aprendizaje continuo sobre virtualización, Linux, Docker, redes, automatización y servicios autoalojados.

## Objetivos

- Aprender virtualización con Proxmox.
- Implementar una arquitectura basada en Docker.
- Construir una nube privada.
- Centralizar servicios multimedia.
- Implementar monitoreo.
- Automatizar tareas.
- Documentar cada decisión técnica.
- Mantener un proyecto reproducible.

## Tecnologías

- Proxmox VE
- Debian
- Docker
- Docker Compose
- Portainer
- AdGuard Home
- Jellyfin
- Immich
- Nextcloud
- Vaultwarden
- Grafana
- Prometheus
- Home Assistant
- Cloudflare
- Hermes Agent
- OpenRouter

## Infraestructura actual

| Componente | Tecnología | Operación |
|---|---|---|
| Hipervisor | Proxmox VE 9 | Siempre activo |
| Router | OpenWrt | Siempre activo |
| DNS | AdGuard Home | Siempre activo |
| Plataforma de contenedores | Docker Engine en VM 200 | Siempre activa |
| Proxy y acceso remoto | Traefik v3 + Cloudflare Tunnel | Siempre activos |
| Administración y estado | Portainer, Homepage y Uptime Kuma | Siempre activos |
| Aplicaciones principales | Nextcloud y Vaultwarden | Siempre activas |
| Agente | Hermes Agent en VM 400 | Siempre activo |
| Automatización doméstica | Home Assistant OS en VM 300 | Bajo demanda |
| Multimedia | Immich y Jellyfin | Bajo demanda |
| Observabilidad pesada | Prometheus, Grafana y cAdvisor | Bajo demanda |
| Métricas ligeras | Node Exporter | Siempre activo |

La documentación se organiza en:

- [`docs/architecture/`](docs/architecture/) para la topología y decisiones de
  alto nivel;
- [`docs/networking/`](docs/networking/) para direccionamiento y DNS;
- [`docs/services/`](docs/services/) para cada servicio;
- [`docs/runbooks/`](docs/runbooks/) para operación, respaldo y recuperación.
