# Nextcloud backup runbook

## Alcance

El respaldo consistente contiene cuatro piezas inseparables:

- `database.dump`: exportación PostgreSQL en formato custom.
- `application.tar.gz`: aplicación, Compose, configuración y secretos.
- `user-data.tar.gz`: archivos almacenados en el disco de 500 GB.
- `SHA256SUMS` y `manifest.txt`: integridad y trazabilidad.

El script activa el modo mantenimiento, genera y verifica los artefactos, lo
desactiva incluso ante errores y conserva los tres conjuntos más recientes.

## Consideración de almacenamiento

El disco `scsi1` de 500 GB tiene `backup=0` en Proxmox. Por lo tanto, un `vzdump`
de la VM no protege los datos de usuarios. Los conjuntos creados localmente deben
ser copiados al almacenamiento USB `qlab-usb-backup` mediante una tarea iniciada
desde Proxmox. No habilite el timer hasta completar y verificar esa transferencia.

## Instalación

```bash
install -m 0750 scripts/backup-nextcloud.sh \
  /opt/quesadalab/scripts/backup-nextcloud.sh

install -m 0644 systemd/backup-nextcloud.service \
  /etc/systemd/system/backup-nextcloud.service

install -m 0644 systemd/backup-nextcloud.timer \
  /etc/systemd/system/backup-nextcloud.timer

systemctl daemon-reload
```

No habilite el timer todavía. Primero ejecute un respaldo manual, transfiera el
conjunto al USB y complete una prueba de restauración aislada.

## Preflight y ejecución manual

```bash
findmnt /srv/nextcloud-data
df -h /opt/quesadalab /srv/nextcloud-data
docker inspect -f '{{.State.Status}} {{.State.Health.Status}}' nextcloud nextcloud-db

/opt/quesadalab/scripts/backup-nextcloud.sh
echo "backup-exit=$?"
```

## Verificación

```bash
backup_dir="$(find /opt/quesadalab/backups/nextcloud \
  -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1)"

(cd "$backup_dir" && sha256sum --check SHA256SUMS)
tar -tzf "$backup_dir/application.tar.gz" >/dev/null
tar -tzf "$backup_dir/user-data.tar.gz" >/dev/null
docker exec --user www-data nextcloud php occ maintenance:mode
```

El último comando debe indicar que el modo mantenimiento está desactivado.

## Retención externa

La copia USB debe conservar al menos tres respaldos completos. La transferencia
debe copiar primero a un directorio temporal, verificar `SHA256SUMS` en Proxmox y
renombrar el directorio solamente después de una verificación correcta.
