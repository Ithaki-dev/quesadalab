# ADR-002

# Adopción de OpenWrt como Router Principal

## Estado

Aceptado

---

## Contexto

Inicialmente se utilizó el firmware original del router Linksys.

Se detectó que el firmware no permitía un control adecuado sobre DHCP y DNS, limitando la integración con AdGuard Home.

---

## Decisión

Se reemplazó el firmware por OpenWrt 24.10.

---

## Razones

- Mayor control del DHCP.
- Gestión avanzada del DNS.
- Firewall configurable.
- Soporte para WireGuard.
- Soporte para VLAN.
- Integración con servicios self-hosted.

---

## Consecuencias

OpenWrt será la plataforma oficial de red de QuesadaLab.

Todos los servicios futuros asumirán OpenWrt como infraestructura base.