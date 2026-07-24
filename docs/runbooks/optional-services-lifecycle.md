# Operacion bajo demanda de Immich y Jellyfin

Immich y Jellyfin pueden permanecer detenidos cuando no se utilizan. Esto libera
memoria y CPU dentro de `docker01`, especialmente para n8n, sin eliminar datos,
contenedores ni configuracion.

Detener estos stacks no reduce automaticamente la memoria asignada a la VM 200.
Antes de aumentar la RAM de la futura VM de Hermes, revise tambien la memoria
disponible en Proxmox y la configuracion de memoria o ballooning de `docker01`.

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

La memoria liberada dentro de `docker01` beneficia directamente a n8n. La RAM
para Hermes, al residir en una VM separada, debe reservarse con base en la
memoria disponible real del host y no solo en las metricas de contenedores.

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
