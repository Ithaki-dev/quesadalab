# Arquitectura General

El laboratorio se basa en una Dell OptiPlex 9020 MT ejecutando Proxmox VE.

Todos los servicios serán desplegados utilizando una combinación de:

- Contenedores LXC
- Máquinas virtuales
- Docker Compose

Los servicios de infraestructura se ejecutarán en contenedores LXC mientras que las aplicaciones se desplegarán dentro de una máquina virtual Ubuntu Server utilizando Docker.

## Objetivos de diseño

- Bajo consumo de recursos.
- Alta disponibilidad dentro del entorno doméstico.
- Facilidad de mantenimiento.
- Facilidad de respaldo.
- Arquitectura reproducible.