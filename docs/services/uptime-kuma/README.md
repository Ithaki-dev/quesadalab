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

## Confianza en la PKI interna

Uptime Kuma carga la CA raiz publica de QuesadaLab mediante
`NODE_EXTRA_CA_CERTS`. Esto permite validar los certificados TLS de servicios
internos como `nextcloud.lab` sin desactivar la verificacion de certificados.

El contenedor monta el siguiente archivo como solo lectura:

```
/opt/quesadalab/security/pki/root/root.crt
```

Antes de desplegar, el archivo debe existir en `docker01` y contener un
certificado PEM valido. No se deben montar claves privadas ni la clave de la CA
intermedia en el contenedor.

Despues del despliegue se puede comprobar la configuracion con:

```bash
docker exec uptime-kuma node -p \
  'process.env.NODE_EXTRA_CA_CERTS'

docker exec uptime-kuma node -e '
const https = require("https");
https.get("https://nextcloud.lab/status.php", response => {
  console.log(`HTTP ${response.statusCode}`);
  response.resume();
}).on("error", error => {
  console.error(error.message);
  process.exitCode = 1;
});
'
```

El resultado esperado es la ruta del certificado y `HTTP 200`.
