# Arquitectura General

El laboratorio se basa en una Dell OptiPlex 9020 MT ejecutando Proxmox VE.

Todos los servicios serán desplegados utilizando una combinación de:

- Contenedores LXC
- Máquinas virtuales
- Docker Compose

Los servicios de infraestructura se ejecutan en contenedores LXC, mientras que
la mayoría de las aplicaciones se despliegan dentro de la VM `docker01` con
Docker Compose. Home Assistant es la excepción deliberada: utiliza una VM
dedicada con Home Assistant OS para conservar Supervisor, add-ons, actualizaciones
administradas y respaldos nativos.

## Máquinas virtuales principales

| VMID | Nombre | Función |
|---|---|---|
| 200 | `docker01` | Plataforma de aplicaciones Docker y Traefik |
| 300 | `homeassistant` | Home Assistant OS 17.3 |

## Objetivos de diseño

- Bajo consumo de recursos.
- Alta disponibilidad dentro del entorno doméstico.
- Facilidad de mantenimiento.
- Facilidad de respaldo.
- Arquitectura reproducible.
