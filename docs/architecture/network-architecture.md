# Arquitectura de Red

La red de QuesadaLab usa OpenWrt como router principal y Proxmox VE como
plataforma de virtualización.

OpenWrt proporciona:

- gateway LAN;
- firewall;
- DHCP;
- gestión de clientes.

AdGuard Home se ejecuta en LXC 100 y actúa como DNS principal de la red local.
Los nombres internos `*.lab` resuelven hacia Traefik en `docker01`
(`192.168.1.30`) salvo excepciones explícitas documentadas.

## Rutas principales

- Clientes LAN → OpenWrt → AdGuard para resolución DNS.
- Clientes LAN → Traefik para aplicaciones internas.
- Cloudflare Access → Cloudflare Tunnel → Homepage para acceso remoto
  controlado.
- Hermes en `agent01` → OmniRoute y proveedores externos.
- Prometheus → Node Exporter siempre activo.
- Prometheus → cAdvisor únicamente cuando cAdvisor está encendido bajo demanda.
- Grafana → Prometheus cuando Grafana está encendido bajo demanda.

## Servicios y direcciones

| Componente | Dirección / ruta | Estado |
|---|---|---|
| OpenWrt | `192.168.1.1` | Siempre activo |
| Proxmox `quesada` | `192.168.1.10` | Crítico |
| AdGuard LXC 100 | `192.168.1.20` | Crítico |
| Traefik / Docker VM 200 | `192.168.1.30` | Crítico |
| Home Assistant VM 300 | `192.168.1.40:8123` | En retirada |
| Hermes VM 400 | `192.168.1.60` | Crítico |

## Acceso remoto

El acceso remoto al dashboard principal usa:

```text
cloud.ithakidev.com -> Cloudflare Access -> Cloudflare Tunnel -> Homepage
```

El conector `cloudflared` hace conexiones salientes desde `docker01`. El router
no publica puertos entrantes para estos servicios.

## Home Assistant

Home Assistant conserva el backend HAOS en `192.168.1.40:8123`, pero
`homeassistant.lab` resuelve a Traefik para aplicar TLS, restricciones LAN y
cabeceras de seguridad. El servicio está en retirada y pendiente de eliminación
futura; no debe documentarse como servicio bajo demanda activo.

## Hermes y proveedores externos

Hermes reside en `agent01` (`192.168.1.60`) y se comunica hacia proveedores
externos según la configuración viva de cada perfil. OpenRouter puede existir
como proveedor externo directo en perfiles o como backend configurado dentro de
OmniRoute. No confundir OpenRouter con OmniRoute: OmniRoute es el gateway
interno en `docker01`; OpenRouter es un proveedor externo.

## Observabilidad

Prometheus es permanente y está expuesto internamente mediante
`http://prometheus.lab`. Grafana y cAdvisor permanecen bajo demanda. Si cAdvisor
está apagado, su target en Prometheus aparecerá `DOWN` por diseño.
