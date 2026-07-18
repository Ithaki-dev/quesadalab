# Nextcloud backup runbook

## Alcance

El respaldo consistente contiene cuatro piezas inseparables:

- `database.dump`: exportación PostgreSQL en formato custom.
- `application.tar.gz`: aplicación, Compose, configuración y secretos.
- `user-data.tar.gz`: archivos almacenados en el disco de 500 GB.
- `SHA256SUMS` y `manifest.txt`: integridad y trazabilidad.

El script activa el modo mantenimiento, genera y verifica los artefactos, lo
desactiva incluso ante errores y conserva un conjunto local. Proxmox conserva
separadamente los siete conjuntos USB más recientes.

## Consideración de almacenamiento

El disco `scsi1` de 500 GB tiene `backup=0` en Proxmox. Por lo tanto, un `vzdump`
de la VM no protege los datos de usuarios. Los conjuntos creados localmente deben
ser copiados al almacenamiento USB `qlab-usb-backup` mediante una tarea iniciada
desde Proxmox con una llave limitada a `rrsync -ro`. La llave no permite shell,
escritura ni acceso fuera del directorio local de respaldos.

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

Después de la primera prueba manual, el timer local se programa a las 03:00. La
réplica desde Proxmox se programa a las 04:00.

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

## Instalación del pull en Proxmox

Requisitos ya establecidos:

- USB montado en `/mnt/quesadalab-backup`.
- Llave privada `/root/.ssh/quesadalab-nextcloud-backup`, modo `0600`.
- Clave pública restringida por IP y `rrsync -ro` en `docker01`.

```bash
install -m 0750 scripts/pull-nextcloud-backups.sh \
  /usr/local/sbin/pull-nextcloud-backups.sh

install -m 0644 systemd/pull-nextcloud-backups.service \
  /etc/systemd/system/pull-nextcloud-backups.service

install -m 0644 systemd/pull-nextcloud-backups.timer \
  /etc/systemd/system/pull-nextcloud-backups.timer

systemctl daemon-reload
```

Ejecute primero `/usr/local/sbin/pull-nextcloud-backups.sh` manualmente. Un conjunto
nuevo se copia a `.incoming.*`, se valida con `SHA256SUMS` y se mueve atómicamente
a `/mnt/quesadalab-backup/nextcloud/YYYY-MM-DD_HH-MM-SS`.

## Activación final

Solo después de un respaldo local y un pull USB correctos:

```bash
# docker01
systemctl enable --now backup-nextcloud.timer

# Proxmox
systemctl enable --now pull-nextcloud-backups.timer
```

Verifique ambos calendarios y confirme que el pull se ejecute después del respaldo.

## Retención externa

La copia USB conserva los siete conjuntos completos más recientes. La retención de
Proxmox configurada en `pvesm` aplica a `vzdump`, no a estos conjuntos; por eso el
script de pull gestiona su propia retención.
