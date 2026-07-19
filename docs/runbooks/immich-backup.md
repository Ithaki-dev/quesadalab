# Immich backup runbook

## Alcance

Cada snapshot USB contiene:

- `metadata/database.sql.gz`: PostgreSQL con limpieza previa a restauracion;
- `metadata/configuration.tar.gz`: Compose, entorno privado y secreto de base;
- `media/`: copia completa de `UPLOAD_LOCATION`;
- checksums y manifests para integridad y trazabilidad.

La base se exporta primero y la biblioteca despues. Este es el orden recomendado
por Immich cuando no se detiene el servidor: el peor caso es un archivo huerfano,
no una referencia de base de datos hacia un archivo ausente.

No se crea un tar local de la biblioteca. El disco raiz de la VM es menor que el
disco Immich de 200 GiB, por lo que Proxmox hace pull directo al HDD USB. Los
snapshots posteriores usan hard links para archivos que no cambiaron.

## Instalacion en docker01

```bash
install -m 0750 scripts/prepare-immich-backup.sh \
  /opt/quesadalab/scripts/prepare-immich-backup.sh

install -m 0750 scripts/serve-immich-backups.sh \
  /opt/quesadalab/scripts/serve-immich-backups.sh

install -m 0644 systemd/prepare-immich-backup.service \
  /etc/systemd/system/prepare-immich-backup.service

install -m 0644 systemd/prepare-immich-backup.timer \
  /etc/systemd/system/prepare-immich-backup.timer

systemctl daemon-reload
```

La llave publica dedicada en `authorized_keys` debe incluir restriccion por IP,
`restrict` y este comando forzado:

```text
command="/opt/quesadalab/scripts/serve-immich-backups.sh"
```

El comando forzado solo acepta operaciones sender de rsync para:

- `/opt/quesadalab/backups/immich`;
- `/srv/immich-data/library`.

## Instalacion en Proxmox

La llave privada dedicada se guarda en
`/root/.ssh/quesadalab-immich-backup` con modo `0600`.

```bash
install -m 0750 scripts/pull-immich-backups.sh \
  /usr/local/sbin/pull-immich-backups.sh

install -m 0644 systemd/pull-immich-backups.service \
  /etc/systemd/system/pull-immich-backups.service

install -m 0644 systemd/pull-immich-backups.timer \
  /etc/systemd/system/pull-immich-backups.timer

systemctl daemon-reload
```

## Prueba manual

Primero en `docker01`:

```bash
/opt/quesadalab/scripts/prepare-immich-backup.sh
```

Luego en Proxmox:

```bash
/usr/local/sbin/pull-immich-backups.sh
```

Verifique `SHA256SUMS`, el contenido de `media`, que no queden directorios
`.incoming.*` y que Immich siga respondiendo HTTP 200.

## Activacion

Solo despues de una prueba completa:

```bash
# docker01
systemctl enable --now prepare-immich-backup.timer

# Proxmox
systemctl enable --now pull-immich-backups.timer
```

La preparacion corre a la 01:00 y el pull a la 01:15. Si la biblioteca tarda mas
de quince minutos en transferirse por primera vez, ejecute el primer pull manual
antes de activar el timer; los siguientes snapshots seran incrementales.
