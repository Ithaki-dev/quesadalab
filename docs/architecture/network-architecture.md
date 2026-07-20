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

---

## Arquitectura

```text
                    Internet
                         │
                         ▼
                    ISP Modem
                         │
                         ▼
                OpenWrt Router
                 192.168.1.1
                         │
            DHCP + Firewall + Routing
                         │
                         ▼
                AdGuard Home
                 192.168.1.20
                         ├──────────────► Traefik / Docker
                         │                192.168.1.30
                         │                       │
                         │                       ▼
                         │              Home Assistant OS
                         │                192.168.1.40
                         │
                         ▼
          DNS-over-HTTPS / DNS-over-TLS
                  Cloudflare DNS

──────────────────────────────────────────────

Clientes

• Windows PC
• Smart TVs
• Echo Dot
• Teléfonos
• Futuras máquinas virtuales
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
