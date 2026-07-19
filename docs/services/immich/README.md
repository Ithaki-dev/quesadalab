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

## Seguridad

- La contrasena de PostgreSQL se lee desde un Docker Secret.
- La base se inicializa con checksums de datos.
- No se publica el puerto 2283 directamente en el host.
- Traefik aplica restriccion LAN y cabeceras globales.
- `IMMICH_ALLOW_SETUP=false` impide reabrir el registro inicial.
- Traefik sirve un certificado dedicado para `immich.lab`, emitido por la PKI
  interna y validado por los clientes de la LAN.

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

## Estado validado

La fase quedo cerrada el 18 de julio de 2026 con estas comprobaciones:

- los cuatro contenedores (`server`, PostgreSQL, Valkey y Machine Learning)
  reportan estado saludable;
- web y `https://immich.lab/api/server/ping` responden HTTP 200;
- el certificado dedicado serial `1003` valida `immich.lab`;
- el disco ext4 de 200 GiB esta montado por UUID en `/srv/immich-data`;
- `IMMICH_ALLOW_SETUP=false` esta aplicado en el contenedor;
- login, consulta y carga de fotografias funcionan desde web y aplicacion movil;
- Uptime Kuma valida cada 60 segundos DNS, TLS, HTTP 200 y la palabra `pong`;
- la preparacion local systemd genera dump, configuracion, checksums y manifest;
- Proxmox conserva tres snapshots USB incrementales y no deja `.incoming.*`;
- la incrementalidad se comprobo con el mismo inodo y `links=2` entre snapshots;
- los timers quedaron activos a la 01:00 (preparacion) y 01:15 (pull USB).

La cuenta inicial permanece sin cuota. Antes de agregar usuarios, revise el uso
agregado y defina cuotas si la capacidad disponible no permite el crecimiento
esperado.

