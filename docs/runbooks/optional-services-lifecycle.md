# Operación de servicios bajo demanda

Immich, Jellyfin y el grupo de monitorización pueden permanecer detenidos
cuando no se utilizan. Home Assistant VM 300 también opera bajo demanda. Esto
reserva memoria y CPU para Hermes sin eliminar datos, contenedores ni
configuración.

Detener estos stacks no reduce automaticamente la memoria asignada a la VM 200.
Hermes ya reside en VM 400 con 4 vCPU y 4 GiB. Antes de cambiar recursos, revise
la memoria disponible real en Proxmox y la configuración de todas las VM.

## Componentes relacionados

| Servicio | Stack en `docker01` | Timer local | Timer USB en `quesada` |
| --- | --- | --- | --- |
| Immich | `/opt/quesadalab/stacks/immich` | `prepare-immich-backup.timer` | `pull-immich-backups.timer` |
| Jellyfin | `/opt/quesadalab/stacks/jellyfin` | `backup-jellyfin.timer` | `pull-jellyfin-backups.timer` |

La politica habitual es:

| Componente | Estado habitual |
| --- | --- |
| Uptime Kuma | Siempre activo |
| Node Exporter | Siempre activo |
| Grafana | Bajo demanda |
| Prometheus | Bajo demanda |
| cAdvisor | Bajo demanda |
| Immich | Bajo demanda |
| Jellyfin | Bajo demanda |
| Home Assistant VM 300 | Bajo demanda |
| Hermes VM 400 | Siempre activo |

Ponga tambien los monitores correspondientes de Uptime Kuma en mantenimiento.
No elimine los monitores ni desactive DNS o TLS.

## Apagado planificado

Si desea una ultima copia antes del apagado, ejecute primero en `docker01`:

```bash
systemctl start prepare-immich-backup.service
systemctl start backup-jellyfin.service

systemctl show prepare-immich-backup.service backup-jellyfin.service \
  --property=Id --property=Result --property=ExecMainStatus
```

Luego copie los respaldos preparados al USB desde `quesada`:

```bash
findmnt /mnt/quesadalab-backup
systemctl start pull-immich-backups.service
systemctl start pull-jellyfin-backups.service

systemctl show pull-immich-backups.service pull-jellyfin-backups.service \
  --property=Id --property=Result --property=ExecMainStatus
```

Desactive los timers locales en `docker01` para evitar trabajos mientras los
servicios permanecen apagados:

```bash
systemctl disable --now \
  prepare-immich-backup.timer \
  backup-jellyfin.timer
```

Desactive los pulls correspondientes en `quesada`:

```bash
systemctl disable --now \
  pull-immich-backups.timer \
  pull-jellyfin-backups.timer
```

Finalmente, detenga los stacks en `docker01`:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/immich \
  --env-file /opt/quesadalab/stacks/immich/.env \
  --file /opt/quesadalab/stacks/immich/docker-compose.yml \
  stop --timeout 120

docker compose \
  --project-directory /opt/quesadalab/stacks/jellyfin \
  --env-file /opt/quesadalab/stacks/jellyfin/.env \
  --file /opt/quesadalab/stacks/jellyfin/docker-compose.yml \
  stop --timeout 120
```

Use `stop`, no `down --volumes`: los volumenes y datos persistentes deben
conservarse. Mientras dure el mantenimiento, Traefik puede responder 502 o 503
solo para esos dos nombres.

Compruebe el resultado:

```bash
docker ps --all \
  --filter name=immich \
  --filter name=jellyfin \
  --format 'table {{.Names}}\t{{.Status}}'

free -h
docker stats --no-stream

curl --silent --show-error --output /dev/null \
  --write-out 'Nextcloud HTTP %{http_code}\n' \
  https://nextcloud.lab/status.php

curl --silent --show-error --output /dev/null \
  --write-out 'Vaultwarden HTTP %{http_code}\n' \
  https://vault.lab/alive
```

## Encendido planificado

Primero confirme en `docker01` que ambos discos estan montados:

```bash
findmnt /srv/immich-data
findmnt /srv/jellyfin-media
df -hT /srv/immich-data /srv/jellyfin-media
```

Inicie los stacks existentes:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/immich \
  --env-file /opt/quesadalab/stacks/immich/.env \
  --file /opt/quesadalab/stacks/immich/docker-compose.yml \
  start

docker compose \
  --project-directory /opt/quesadalab/stacks/jellyfin \
  --env-file /opt/quesadalab/stacks/jellyfin/.env \
  --file /opt/quesadalab/stacks/jellyfin/docker-compose.yml \
  start
```

Si cambiaron Compose, variables o imagenes, use `./deploy.sh immich` o
`./deploy.sh jellyfin` desde `/opt/quesadalab-repo` en lugar de `start`.

Espere y valide:

```bash
docker inspect immich-server jellyfin \
  --format 'name={{.Name}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'

curl --silent --show-error \
  https://immich.lab/api/server/ping

curl --silent --show-error --output /dev/null \
  --write-out 'Jellyfin HTTP %{http_code}\n' \
  https://jellyfin.lab/health
```

Reactive los timers locales en `docker01`:

```bash
systemctl enable --now \
  prepare-immich-backup.timer \
  backup-jellyfin.timer
```

Reactive los timers USB en `quesada`:

```bash
systemctl enable --now \
  pull-immich-backups.timer \
  pull-jellyfin-backups.timer
```

Quite el mantenimiento en Uptime Kuma solamente despues de obtener HTTP 200 y
estado saludable en ambos servicios.

## Revision de recursos

En `docker01`:

```bash
free -h
docker stats --no-stream
```

En `quesada`:

```bash
free -h
qm config 200 | grep -E '^(memory|balloon):'
```

La memoria liberada dentro de `docker01` aumenta la disponibilidad del host,
pero la RAM de Hermes está reservada en una VM separada. Tome decisiones con
`MemAvailable`, swap y el inventario completo de VM, no solo con métricas de
contenedores.

## Grupo de monitorizacion bajo demanda

Node Exporter permanece activo para mantener disponible el endpoint ligero de
metricas del host. Grafana, Prometheus y cAdvisor se administran juntos como el
grupo `monitoring`. Cuando Prometheus esta apagado no se almacenan muestras y el
periodo correspondiente aparecera vacio en Grafana.

Para detener el grupo en `docker01`, detenga primero la interfaz y la base de
metricas, y luego el recolector de contenedores:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/grafana \
  --env-file /opt/quesadalab/stacks/grafana/.env \
  --file /opt/quesadalab/stacks/grafana/docker-compose.yml \
  stop --timeout 60

docker compose \
  --project-directory /opt/quesadalab/stacks/prometheus \
  --file /opt/quesadalab/stacks/prometheus/docker-compose.yml \
  stop --timeout 120

docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  stop --timeout 60
```

Compruebe que Node Exporter continua en ejecucion:

```bash
docker ps --all \
  --filter name=grafana \
  --filter name=prometheus \
  --filter name=cadvisor \
  --filter name=node-exporter \
  --format 'table {{.Names}}\t{{.Status}}'

docker inspect node-exporter \
  --format 'name={{.Name}} status={{.State.Status}}'
```

Para iniciar el grupo, use el orden recolector, base de metricas e interfaz:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  start

docker compose \
  --project-directory /opt/quesadalab/stacks/prometheus \
  --file /opt/quesadalab/stacks/prometheus/docker-compose.yml \
  start

docker compose \
  --project-directory /opt/quesadalab/stacks/grafana \
  --env-file /opt/quesadalab/stacks/grafana/.env \
  --file /opt/quesadalab/stacks/grafana/docker-compose.yml \
  start
```

Valide el arranque sin depender de que los contenedores tengan healthcheck:

```bash
docker ps \
  --filter name=grafana \
  --filter name=prometheus \
  --filter name=cadvisor \
  --filter name=node-exporter \
  --format 'table {{.Names}}\t{{.Status}}'

curl --silent --show-error --output /dev/null \
  --write-out 'Grafana HTTP %{http_code}\n' \
  http://grafana.lab/login

curl --silent --show-error --output /dev/null \
  --write-out 'Prometheus HTTP %{http_code}\n' \
  http://prometheus.lab/-/ready
```

Use `stop`, nunca `down --volumes`, para conservar la base TSDB de Prometheus,
los dashboards y la configuracion de Grafana. Estos tres servicios no requieren
desactivar timers porque actualmente no poseen trabajos systemd programados.

## Home Assistant bajo demanda

Antes de iniciar VM 300:

```bash
free -h
qm status 300
qm config 300 | grep -E '^(memory|onboot):'
```

Si existe capacidad suficiente:

```bash
qm start 300
qm agent 300 ping
curl --silent --show-error --output /dev/null \
  --write-out 'Home Assistant HTTP %{http_code}\n' \
  https://homeassistant.lab/
```

Quite el mantenimiento del monitor solo después de obtener HTTP 200. Para
devolver recursos a Hermes, apague Home Assistant desde el sistema invitado,
espere `status: stopped` y mantenga `onboot=0`:

```bash
qm shutdown 300 --timeout 180
qm status 300
qm set 300 --onboot 0
```

Pause nuevamente el monitor de Uptime Kuma. El job `homeassistant-daily` debe
permanecer deshabilitado durante apagados prolongados; haga un respaldo manual
antes de cambios importantes.
