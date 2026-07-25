# Arquitectura de Red

## Descripción

La infraestructura de red de QuesadaLab está basada en OpenWrt como router principal y Proxmox VE como plataforma de virtualización.

OpenWrt proporciona los servicios de red fundamentales:

- Gateway
- Firewall
- Servidor DHCP
- Gestión de clientes
- Resolución de nombres locales

AdGuard Home se ejecuta en un contenedor LXC Debian dentro de Proxmox y actúa como servidor DNS principal para toda la red doméstica.

Las aplicaciones HTTPS internas resuelven a Traefik en `192.168.1.30`.
Home Assistant mantiene su backend HAOS en `192.168.1.40:8123`, pero
`homeassistant.lab` resuelve a Traefik para aplicar TLS, restricciones LAN y
cabeceras de seguridad de forma coherente.

Hermes reside en `agent01` (`192.168.1.60`) y se comunica hacia Internet para
usar OpenRouter y las API de Discord, Telegram y Gmail. No acepta conexiones
públicas entrantes.

El acceso remoto al dashboard sigue una ruta independiente:
`cloud.ithakidev.com -> Cloudflare Access -> Cloudflare Tunnel -> Homepage`.
El conector `cloudflared` realiza únicamente conexiones salientes desde
`docker01`; el router no publica puertos.

---

## Arquitectura

```text
 Internet
    │
    ├── Cloudflare Access ── Tunnel saliente ── Homepage (`docker01`)
    │
 ISP / OpenWrt 192.168.1.1
    │
    ├── AdGuard Home 192.168.1.20
    │      └── DNS interno y reenvío cifrado
    │
    ├── docker01 192.168.1.30
    │      ├── Traefik
    │      ├── servicios Docker
    │      └── cloudflared
    │
    ├── Home Assistant OS 192.168.1.40 (bajo demanda)
    │
    └── agent01 / Hermes 192.168.1.60
           └── OpenRouter + Discord + Telegram + Gmail

──────────────────────────────────────────────

Clientes

• Windows PC
• Smart TVs
• Echo Dot
• Teléfonos
• Clientes administrados
```

---

## Objetivos

- Centralizar la administración de la red.
- Proporcionar filtrado DNS.
- Mejorar la privacidad.
- Reducir publicidad.
- Preparar la infraestructura para futuros servicios.

---

## Estado

✅ Operativo
