# Nextcloud

## Alcance

Nextcloud atiende hasta cinco usuarios internos en `https://nextcloud.lab`. La
aplicación usa PostgreSQL, Redis, cron y Traefik. Los archivos de usuarios residen
en el disco dedicado montado en `/srv/nextcloud-data`.

## Rutas

| Elemento | Ruta |
|---|---|
| Stack activo | `/opt/quesadalab/stacks/nextcloud` |
| Aplicación | `/opt/quesadalab/data/nextcloud/html` |
| PostgreSQL | `/opt/quesadalab/data/nextcloud/postgres` |
| Datos de usuarios | `/srv/nextcloud-data/user-data` |
| Secretos | `/opt/quesadalab/security/nextcloud` |
| Configuración PHP | `/opt/quesadalab/config/nextcloud/php` |

## Ajustes posteriores a la instalación

Los siguientes valores se aplican una vez, después de verificar el primer backup:

```bash
docker exec --user www-data nextcloud \
  php occ config:app:set files default_quota --value='75 GB'

docker exec --user www-data nextcloud \
  php occ user:setting rquesada files quota '75 GB'

docker exec --user www-data nextcloud \
  php occ config:system:set default_phone_region --value=CR

docker exec --user www-data nextcloud \
  php occ config:system:set maintenance_window_start --type=integer --value=5

docker exec --user www-data nextcloud \
  php occ maintenance:repair --include-expensive
```

La ventana comienza a las 05:00 UTC (23:00 en Costa Rica) y termina antes del
backup local de las 03:00. La cuota deja espacio para base de datos, versiones,
papelera, crecimiento y operación del disco de 500 GB.

## Cabeceras HTTPS

El middleware `nextcloud-headers` se aplica después de las cabeceras globales y
establece `SAMEORIGIN`, `noindex, nofollow` y HSTS por 180 días. Esto evita cambiar
la política de otros servicios publicados por Traefik.

```bash
curl --silent --show-error --head https://nextcloud.lab/login |
  grep -Ei '^(HTTP/|strict-transport-security:|x-frame-options:|x-robots-tag:)'
```

## Validación

```bash
docker exec --user www-data nextcloud php occ status
docker exec --user www-data nextcloud php occ setupchecks

docker inspect \
  --format 'status={{.State.Status}} health={{.State.Health.Status}}' \
  nextcloud nextcloud-db nextcloud-redis

curl --silent --show-error --output /dev/null \
  --write-out 'HTTP %{http_code}\n' https://nextcloud.lab/status.php
```

Revise además inicio de sesión, subida, descarga y sincronización WebDAV desde un
cliente real.

## Respaldos

El timer local ejecuta el backup a las 03:00 y conserva un conjunto. Proxmox lo
copia al USB a las 04:00 mediante una llave `rrsync` de solo lectura y conserva
siete conjuntos. Consulte los runbooks de backup y restauración antes de operar
manualmente.

## Secreto de instalación

`nextcloud_admin_password` solo inicializa una instalación vacía. Después de que el
administrador cambia su contraseña, sustituya ese archivo por un valor aleatorio
nuevo sin imprimirlo. Una restauración completa conserva la contraseña actual en
PostgreSQL.
