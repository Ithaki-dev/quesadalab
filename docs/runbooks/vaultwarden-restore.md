# Vaultwarden restore runbook

## Advertencia

Una restauración reemplaza datos y configuración activa. Nunca debe ejecutarse en
producción sin backup preventivo, aprobación explícita, ventana de mantenimiento y
plan de rollback.

El script existe y su sintaxis está validada, pero la restauración destructiva no se
considera probada hasta completarla en un entorno aislado.

## Requisitos

- Backup y checksum seleccionados.
- Espacio para extracción y backup preventivo.
- Docker, `tar`, `sha256sum`, `python3` y `curl`.
- Acceso root y ausencia de otro backup o deployment en ejecución.
- Comunicación de la indisponibilidad esperada.

## Rollback

Conservar el backup diario, el backup preventivo, la configuración activa con su
`.env` y el nombre de la imagen en ejecución. Si falla la validación posterior, no
eliminar artefactos ni repetir el proceso: recopilar estados y decidir explícitamente
si se recupera el backup preventivo.

## Validación no destructiva

```bash
cd /opt/quesadalab-repo
bash -n scripts/restore-vaultwarden.sh
command -v docker tar sha256sum python3 curl

find /opt/quesadalab/backups/daily \
  -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -r
```

Revisar el manifest y verificar el checksum sin imprimir secretos.

## Ejecución autorizada

Solo después de aprobar backup, impacto y rollback:

```bash
/opt/quesadalab/scripts/restore-vaultwarden.sh \
  /opt/quesadalab/backups/daily/YYYY-MM-DD_HH-MM-SS
```

El operador debe escribir `RESTAURAR` cuando el script solicite confirmación.

## Verificación posterior

```bash
docker inspect \
  --format 'status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
  vaultwarden

curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' https://vault.lab/alive
```

Validar también el inicio de sesión con un cliente autorizado sin documentar datos
del vault.

## Prueba aislada pendiente

Restaurar una copia con rutas, hostname, contenedor y red aislados, sin montar los
datos activos ni publicar `vault.lab`. Validar SQLite, arranque y autenticación antes
de eliminar controladamente el entorno temporal.
