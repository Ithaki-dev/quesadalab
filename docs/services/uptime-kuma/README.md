# Uptime Kuma

## Descripción

Uptime Kuma es la plataforma de monitoreo utilizada en QuesadaLab para supervisar la disponibilidad de los servicios de la infraestructura.

Proporciona monitoreo continuo mediante HTTP, HTTPS, TCP, ICMP (Ping), DNS y otros protocolos, además de generar estadísticas de disponibilidad y tiempos de respuesta.

---

## Objetivos

- Supervisar la disponibilidad de los servicios del laboratorio.
- Detectar caídas de servicios de forma inmediata.
- Registrar el historial de disponibilidad.
- Centralizar el monitoreo desde Homepage.

---

## Información del servicio

| Parámetro | Valor |
|-----------|-------|
| Servicio | Uptime Kuma |
| Contenedor | uptime-kuma |
| Imagen | louislam/uptime-kuma:1 |
| Puerto interno | 3001 |
| Acceso | http://kuma.lab |
| Proxy | Traefik |
| Red Docker | proxy |

---

## Integración

Este servicio se integra con:

- Traefik
- Homepage
- Docker
- Proxmox
- AdGuard Home

---

## Estado

✅ Producción

---

## Ubicación

Docker Compose:

```
/opt/quesadalab/stacks/uptime-kuma
```

Datos persistentes:

```
/opt/quesadalab/data/uptime-kuma
```