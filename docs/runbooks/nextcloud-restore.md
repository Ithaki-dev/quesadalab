# Nextcloud restore runbook

## Advertencia

La restauración reemplaza PostgreSQL, la aplicación, secretos y todos los datos de
usuarios. Requiere aprobación explícita, ventana de mantenimiento, espacio libre y
un respaldo preventivo del estado actual. El script debe probarse primero en un
entorno aislado.

## Validación no destructiva

```bash
bash -n scripts/restore-nextcloud.sh
backup_dir=/ruta/al/conjunto
(cd "$backup_dir" && sha256sum --check SHA256SUMS)
tar -tzf "$backup_dir/application.tar.gz" >/dev/null
tar -tzf "$backup_dir/user-data.tar.gz" >/dev/null
```

Revise `manifest.txt` sin imprimir `.env` ni los archivos de secretos.

## Ejecución autorizada

```bash
/opt/quesadalab/scripts/restore-nextcloud.sh /ruta/al/conjunto
```

El operador debe escribir exactamente `RESTORE-NEXTCLOUD`. El script detiene el
stack, restaura los archivos, inicia PostgreSQL y Redis, importa la base de datos y
levanta todos los servicios.

## Verificación posterior

```bash
docker inspect \
  --format 'status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
  nextcloud nextcloud-db nextcloud-redis

docker exec --user www-data nextcloud php occ status

curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' https://nextcloud.lab/status.php
```

Valide inicio de sesión, carga y descarga de un archivo de prueba y el cron. No
elimine el conjunto restaurado ni el respaldo preventivo hasta cerrar la prueba.

## Limitación deliberada

El script no crea automáticamente el respaldo preventivo para evitar llenar el
disco raíz. El operador debe generarlo y comprobar su destino antes de autorizar la
restauración.
