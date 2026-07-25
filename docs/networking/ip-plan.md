# Plan de Direccionamiento

| Servicio | Dirección |
|----------|-----------|
| Router | 192.168.1.1 |
| Proxmox | 192.168.1.10 |
| AdGuard Home | 192.168.1.20 |
| Docker VM | 192.168.1.30 |
| Home Assistant backend (HAOS VM 300) | 192.168.1.40 |
| Cámara IP | 192.168.1.50 |
| Hermes Agent (VM 400 `agent01`) | 192.168.1.60 |

Los nombres de aplicaciones publicados mediante Traefik, incluido
`homeassistant.lab`, resuelven a la VM Docker `192.168.1.30`. La dirección
`192.168.1.40` permanece reservada por DHCP para el backend de HAOS y no es el
destino DNS del usuario final.

`agent01.lab` y `hermes.lab` resuelven directamente a `192.168.1.60` solo en la
red interna. Hermes no se publica mediante Cloudflare Tunnel ni expone SSH a
Internet.

`cloud.ithakidev.com` es un nombre público administrado por Cloudflare. AdGuard
reenvía las consultas de `ithakidev.com` al resolvedor público de Cloudflare
para evitar respuestas negativas obsoletas.
