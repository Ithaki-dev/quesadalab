# Plan de Direccionamiento

| Servicio | Dirección |
|----------|-----------|
| Router | 192.168.1.1 |
| Proxmox | 192.168.1.10 |
| AdGuard Home | 192.168.1.20 |
| Docker VM | 192.168.1.30 |
| Home Assistant backend (HAOS VM 300) | 192.168.1.40 |
| Cámara IP | 192.168.1.50 |

Los nombres de aplicaciones publicados mediante Traefik, incluido
`homeassistant.lab`, resuelven a la VM Docker `192.168.1.30`. La dirección
`192.168.1.40` permanece reservada por DHCP para el backend de HAOS y no es el
destino DNS del usuario final.
