# Vaultwarden backup runbook

## Objetivo e impacto

Crear un backup consistente de los datos y la configuración activa, verificar su
integridad y recuperar el servicio. El script detiene temporalmente el contenedor;
en la prueba del 17 de julio de 2026 tardó aproximadamente 66 segundos en volver a
`healthy`.

## Ubicaciones

| Elemento | Ruta |
|---|---|
| Script live | `/opt/quesadalab/scripts/backup-vaultwarden.sh` |
| Backups | `/opt/quesadalab/backups/daily` |
| Log | `/opt/quesadalab/logs/vaultwarden-backup.log` |
| Timer | `backup-vaultwarden.timer` |

## Preflight

```bash
docker inspect --format '{{.State.Status}}' vaultwarden
df -h /opt/quesadalab
systemctl is-active backup-vaultwarden.timer
```

## Ejecución manual

```bash
cd /opt/quesadalab-repo
./scripts/backup-vaultwarden.sh
echo "backup-exit=$?"
```

Un backup correcto debe detener el contenedor, crear archivo y checksum, verificar
SHA-256 y estructura, crear el manifest, iniciar Vaultwarden, esperar su healthcheck,
comprobar `/alive`, aplicar retención y terminar con código 0.

Una falla del endpoint externo produce una advertencia y no invalida un backup local
íntegro.

## Verificación

```bash
systemctl show backup-vaultwarden.service \
  --property=Result --property=ExecMainStatus --property=ExecMainExitTimestamp

docker inspect \
  --format 'status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
  vaultwarden

curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' https://vault.lab/alive
```

La política conserva los siete conjuntos diarios más recientes. No se deben borrar
backups manualmente durante una ejecución ni iniciar una restauración sin seguir el
runbook correspondiente.
