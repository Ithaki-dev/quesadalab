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

## Estado

Preparado en el repositorio. Pendientes antes de produccion:

1. certificado dedicado para `immich.lab`;
2. configuracion privada y secreto aleatorio;
3. despliegue y creacion del administrador;
4. deshabilitar el endpoint de setup;
5. backup, restauracion y replica USB;
6. monitor en Uptime Kuma;
7. validacion desde las aplicaciones moviles.

