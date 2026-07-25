# Arquitectura General

El laboratorio se basa en una Dell OptiPlex 9020 MT ejecutando Proxmox VE.

Los servicios se despliegan utilizando una combinación de:

- Máquinas virtuales
- Docker Compose

La mayoría de las aplicaciones se ejecutan dentro de la VM `docker01` con
Docker Compose. Home Assistant utiliza una VM dedicada con Home Assistant OS
para conservar Supervisor y add-ons. Hermes utiliza otra VM Debian dedicada
para aislar credenciales, herramientas y canales de mensajería del resto de
las aplicaciones.

## Máquinas virtuales principales

| VMID | Nombre | Recursos | Función | Operación |
|---|---|---|---|---|
| 200 | `docker01` | 4 vCPU, 8 GiB RAM, 80 GiB | Docker, Traefik y servicios | Siempre activa |
| 300 | `homeassistant` | 2 vCPU, 2 GiB RAM, 32 GiB | Home Assistant OS 17.3 | Bajo demanda, `onboot=0` |
| 400 | `agent01` | 4 vCPU, 4 GiB RAM, 64 GiB | Hermes Agent con proveedor externo | Siempre activa |

`agent01` dispone además de 2 GiB de swap de emergencia. No ejecuta un modelo
local: el modelo predeterminado se consume mediante OpenRouter.

## Objetivos de diseño

- Bajo consumo de recursos.
- Continuidad razonable dentro del entorno doméstico.
- Facilidad de mantenimiento.
- Facilidad de respaldo.
- Arquitectura reproducible.
- Separación entre servicios esenciales y cargas bajo demanda.
- Acceso remoto sin puertos entrantes mediante Cloudflare Tunnel y Access.
