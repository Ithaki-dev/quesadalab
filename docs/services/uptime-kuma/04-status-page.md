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

Este grupo incluye:

- Grafana
- Prometheus
- Vaultwarden
- Immich
- Jellyfin
- Nextcloud
- Home Assistant

---

## Configuración

La Status Page utiliza los grupos definidos en Uptime Kuma para organizar los servicios.

Cada monitor se actualiza cada 60 segundos.

Home Assistant se supervisa mediante `https://homeassistant.lab/` cuando VM 300
está en ejecución. El monitor debe permanecer pausado durante su apagado
planificado. Cuando se habilita, acepta códigos 200-299 y conserva la
verificación TLS para validar DNS, PKI interna, Traefik y backend HAOS.

Los monitores de Immich, Jellyfin, Grafana, Prometheus y cAdvisor también deben
entrar en mantenimiento cuando sus stacks estén detenidos deliberadamente.

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
