# Arquitectura General

QuesadaLab se ejecuta sobre una Dell OptiPlex 9020 MT con Proxmox VE 9.2.4.
El host físico usa un Intel Core i7-4790 con 4 núcleos, 8 hilos y
aproximadamente 16 GiB de RAM.

Los servicios se despliegan con una combinación de:

- máquinas virtuales;
- contenedores LXC;
- Docker Compose dentro de `docker01`.

La mayoría de aplicaciones viven dentro de la VM `docker01`. Hermes usa una VM
Debian dedicada para aislar credenciales, herramientas y canales de mensajería.
Home Assistant conserva su VM dedicada, pero está en retirada y pendiente de
eliminación futura.

## Máquinas y contenedores principales

| ID | Nombre | Recursos | Función | Operación |
|---|---|---|---|---|
| LXC 100 | `adguard` | 1 CPU, 512 MiB RAM, 512 MiB swap, 2 GB | DNS LAN y filtrado | Crítico, siempre activo |
| VM 200 | `docker01` | 4 vCPU, 8 GiB RAM, 80 GB | Docker, Traefik y servicios | Crítica, siempre activa |
| VM 300 | `homeassistant` | 2 vCPU, 2 GiB RAM, 32 GB | Home Assistant OS | En retirada, `onboot=0` |
| VM 400 | `agent01` | 4 vCPU, 4 GiB RAM, 64 GB | Hermes Agent | Crítica, siempre activa |

`agent01` dispone además de 2 GiB de swap de emergencia. No ejecuta un modelo
local: consume proveedores externos según la configuración viva del perfil
Hermes. El historial del repo incluye OpenRouter y OmniRoute; valide el
provider activo antes de modificar modelos o credenciales.

La VM `docker01` fue diseñada originalmente con 6 GB de RAM en
[`ADR-004`](../../adr/ADR-004-docker-vm.md). La configuración vigente es 8 GiB
para sostener el conjunto actual de servicios permanentes.

## Política operativa

Críticos y siempre activos:

- Proxmox;
- `docker01`;
- `agent01`;
- AdGuard;
- Traefik;
- Vaultwarden;
- Cloudflare Tunnel;
- OmniRoute.

Siempre activos, no críticos:

- Nextcloud;
- Homepage;
- Uptime Kuma;
- Portainer;
- Node Exporter;
- Prometheus.

Bajo demanda:

- Immich;
- Jellyfin;
- Grafana;
- cAdvisor.

En retirada:

- Home Assistant.

## Observabilidad

Prometheus opera de forma permanente para conservar datos históricos. Grafana y
cAdvisor siguen bajo demanda para reducir consumo cuando no se están usando.
Node Exporter permanece siempre activo.

Prometheus conserva:

- 30 días de retención temporal;
- 5 GB de límite máximo de TSDB;
- almacenamiento persistente en `/opt/quesadalab/data/prometheus`.

El target de cAdvisor permanece configurado en Prometheus. Cuando cAdvisor esté
apagado intencionalmente aparecerá `DOWN`; esa condición debe interpretarse
como servicio bajo demanda detenido, no como falla de Prometheus.

Quesada-Mobile está en planificación. Podrá consultar Prometheus para datos
históricos, pero no debe depender exclusivamente de Prometheus para estado
operativo en tiempo real.

## Objetivos de diseño

- Bajo consumo de recursos.
- Continuidad razonable dentro del entorno doméstico.
- Facilidad de mantenimiento.
- Facilidad de respaldo.
- Arquitectura reproducible.
- Separación entre servicios críticos, permanentes no críticos, cargas bajo
  demanda y servicios en retirada.
- Acceso remoto sin puertos entrantes mediante Cloudflare Tunnel y Access.
