# Immich

## Alcance

Immich proporcionara respaldo y gestion privada de fotografias y videos para
un grupo inicial de hasta cinco usuarios internos. El servicio se publicara en
`https://immich.lab` mediante Traefik y permanecera limitado a la LAN.

La implementacion esta fijada a Immich `v3.0.3`. Los cambios de version deben
revisarse y probarse antes de modificar `IMMICH_VERSION`.

## Arquitectura

| Elemento | Ubicacion |
|---|---|
| Stack activo | `/opt/quesadalab/stacks/immich` |
| Biblioteca | `/srv/immich-data/library` |
| PostgreSQL | `/opt/quesadalab/data/immich/postgres` |
| Cache de modelos | `/opt/quesadalab/data/immich/model-cache` |
| Secreto PostgreSQL | `/opt/quesadalab/security/immich/DB_PASSWORD` |
| Disco dedicado | `scsi2`, 200 GiB, montado en `/srv/immich-data` |
| Backend | Red Docker privada del proyecto Immich |
| Proxy | Red Docker externa `proxy` |

PostgreSQL y Valkey no publican puertos ni se conectan a la red `proxy`. El
servidor es el unico contenedor accesible por Traefik. Machine Learning comienza
en CPU porque la VM no dispone de un dispositivo de render Intel real.

## Seguridad inicial

- La contrasena de PostgreSQL se lee desde un Docker Secret.
- La base se inicializa con checksums de datos.
- No se publica el puerto 2283 directamente en el host.
- Traefik aplica restriccion LAN y cabeceras globales.
- `IMMICH_ALLOW_SETUP` solo permanece activo hasta crear el administrador.
- El certificado dedicado para `immich.lab` debe estar instalado antes del
  despliegue de produccion.

## Recursos

Los limites iniciales protegen una VM de 8 GiB:

| Servicio | Limite de memoria |
|---|---:|
| Immich server | 2 GiB |
| Machine Learning | 2500 MiB |
| PostgreSQL | 768 MiB |
| Valkey | 256 MiB |

Machine Learning usa un proceso y dos hilos por operacion. Estos valores se
revisaran despues de la primera indexacion real.

## Preflight

```bash
getent ahostsv4 immich.lab
findmnt /srv/immich-data
df -hT /srv/immich-data
docker network inspect proxy
```

No despliegue el stack si el disco dedicado no esta montado. De lo contrario,
Docker podria crear la biblioteca en el filesystem raiz de la VM.

## Operacion

El servicio se desplego con certificado dedicado, administrador inicial creado y
`IMMICH_ALLOW_SETUP=false`. La biblioteca reside en el disco dedicado y no esta
incluida en `vzdump` porque `scsi2` usa `backup=0`.

Los procedimientos de proteccion de datos se documentan en:

- `docs/runbooks/immich-backup.md`;
- `docs/runbooks/immich-restore.md`.

La cuenta inicial permanece sin cuota logica. El limite efectivo es la capacidad
del disco; revise regularmente Server Stats y `df -hT /srv/immich-data`.

Pendientes para el cierre total de la fase:

1. probar y activar respaldo y replica USB;
2. agregar monitor HTTPS en Uptime Kuma;
3. validar carga y consulta desde las aplicaciones moviles;
4. registrar resultados finales en esta documentacion.

