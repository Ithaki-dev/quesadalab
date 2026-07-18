# Vaultwarden

## Propósito

Vaultwarden es el gestor de contraseñas privado de QuesadaLab, compatible con los
clientes de Bitwarden. Se publica únicamente en la red interna mediante Traefik y
HTTPS válido.

## Estado

✅ Producción en `docker01`.

El servicio mantiene `SIGNUPS_ALLOWED=false` y dispone de un monitor activo de
Uptime Kuma para `https://vault.lab/alive`.

## Arquitectura

| Componente | Valor |
|---|---|
| Imagen | `vaultwarden/server:latest` |
| Contenedor | `vaultwarden` |
| URL | `https://vault.lab` |
| Health endpoint | `https://vault.lab/alive` |
| Red Docker | `proxy` |
| Datos | `/opt/quesadalab/data/vaultwarden` |
| Stack activo | `/opt/quesadalab/stacks/vaultwarden` |
| Fuente Git | `/opt/quesadalab-repo/stacks/vaultwarden` |

Traefik termina TLS con un certificado emitido por la PKI interna. Vaultwarden
escucha en el puerto 80 únicamente dentro de la red Docker `proxy`.

## Variables y secretos

El archivo `/opt/quesadalab/stacks/vaultwarden/.env` debe pertenecer a `root:root`,
tener permisos `600` y nunca almacenarse en Git.

| Variable | Propósito |
|---|---|
| `DOMAIN` | URL pública interna |
| `SIGNUPS_ALLOWED` | Control del registro público |
| `ADMIN_TOKEN` | Protección de la interfaz administrativa |

La plantilla versionada contiene solo valores ficticios. Nunca se debe mostrar el
contenido completo del archivo activo.

## Despliegue

```bash
cd /opt/quesadalab-repo
./scripts/validate.sh
./deploy.sh vaultwarden --dry-run
./deploy.sh vaultwarden
```

El despliegue predeterminado no descarga imágenes. `--pull` requiere revisión de
versión y una ventana de mantenimiento.

## Verificación

```bash
docker inspect \
  --format 'status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
  vaultwarden

curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' https://vault.lab/alive
```

Se espera `running`, `healthy` y HTTP 200, sin utilizar `curl -k`.

## Seguridad

- Registro público deshabilitado.
- Token administrativo fuerte y fuera de Git.
- `.env` con permisos `600`.
- Acceso limitado a la LAN mediante Traefik.
- HTTPS emitido por la PKI interna.
- Datos persistentes fuera del repositorio.
- Backups restringidos, con checksum y retención.

Comprobación segura del registro:

```bash
docker inspect --format '{{range .Config.Env}}{{println .}}{{end}}' vaultwarden |
awk -F= '
  $1 == "SIGNUPS_ALLOWED" {
    found=1
    if (tolower($2) == "false") print "[OK] Registration is disabled"
    else print "[WARNING] Registration is not disabled"
  }
  END { if (!found) print "[WARNING] SIGNUPS_ALLOWED is missing" }
'
```

## Backup y restore

- [Runbook de backup](../../runbooks/vaultwarden-backup.md)
- [Runbook de restore](../../runbooks/vaultwarden-restore.md)

Los backups de datos residen en `/opt/quesadalab/backups/daily`. Los backups de
configuración de deployments permanecen separados en
`/opt/quesadalab/backups/config-deployments`.

## Monitoreo

- Healthcheck Docker.
- Monitor HTTPS de Uptime Kuma contra `https://vault.lab/alive`.
- Timer systemd y resultado del último backup.
- Métricas del host y contenedor mediante Node Exporter y cAdvisor.

Vaultwarden no expone actualmente métricas específicas a Prometheus.

## Troubleshooting

```bash
docker logs --tail 100 vaultwarden
journalctl -u backup-vaultwarden.service -n 100 --no-pager
systemctl list-timers backup-vaultwarden.timer --no-pager
```

No publicar logs que contengan tokens, contraseñas o contenido del vault.
