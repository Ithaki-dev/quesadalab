# Status Page

## Objetivo

La Status Page de Uptime Kuma proporciona una vista pública o privada del estado de todos los servicios críticos de QuesadaLab.

Permite consultar rápidamente la disponibilidad de la infraestructura sin necesidad de acceder al panel administrativo.

---

## URL

```
http://status.lab
```

---

## Servicios monitorizados

### 🖥 Infraestructura

- Proxmox VE
- Docker VM

### 🌐 Red

- OpenWrt
- AdGuard Home
- Internet

### ⚙️ Servicios Core

- Homepage
- Traefik
- Portainer
- Uptime Kuma

### 📦 Aplicaciones

Los servicios futuros se incorporarán a este grupo:

- Grafana
- Prometheus
- Vaultwarden
- Immich
- Jellyfin
- Nextcloud

---

## Configuración

La Status Page utiliza los grupos definidos en Uptime Kuma para organizar los servicios.

Cada monitor se actualiza cada 60 segundos.

---

## Objetivos

- Supervisión centralizada
- Detección rápida de fallos
- Historial de disponibilidad
- Panel de estado del laboratorio

---

## Buenas prácticas

- Utilizar HTTP para servicios web.
- Utilizar Ping para dispositivos de red.
- Mantener grupos organizados.
- Documentar cada nuevo monitor incorporado.