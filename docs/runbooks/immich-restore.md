# Immich restore runbook

## Advertencia

La restauracion reemplaza la biblioteca, configuracion, secretos y base de datos.
Debe realizarse desde un snapshot USB validado y durante una ventana de
mantenimiento. No use un dump creado por una version incompatible sin revisar
primero las notas de migracion de Immich.

## Instalacion

```bash
install -m 0750 scripts/restore-immich.sh \
  /opt/quesadalab/scripts/restore-immich.sh
```

## Preflight

```bash
findmnt /srv/immich-data
df -hT /srv/immich-data
docker compose --project-directory /opt/quesadalab/stacks/immich \
  --env-file /opt/quesadalab/stacks/immich/.env \
  -f /opt/quesadalab/stacks/immich/docker-compose.yml config --quiet
```

Copie o monte el snapshot USB en `docker01`. Valide previamente:

```bash
(cd SNAPSHOT/metadata && sha256sum --check SHA256SUMS)
gzip -t SNAPSHOT/metadata/database.sql.gz
```

## Restauracion

```bash
/opt/quesadalab/scripts/restore-immich.sh /ruta/al/snapshot
```

El script exige escribir `RESTORE-IMMICH`, detiene el stack, restaura archivos y
mueve la base actual a un directorio `postgres.before-restore-*`. Luego inicia
PostgreSQL sobre un directorio limpio, importa el dump en una transaccion y
vuelve a levantar el stack. Este orden cumple el requisito de restauracion de
Immich v3 y conserva una ruta de rollback local.

## Validacion posterior

Compruebe contenedores saludables, `/api/server/ping`, acceso del administrador,
miniaturas, descarga de originales y trabajos pendientes. Conserve el snapshot
USB hasta terminar la validacion funcional.
