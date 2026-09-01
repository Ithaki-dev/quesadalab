# Operación de servicios bajo demanda

Este runbook cubre únicamente servicios que pueden permanecer apagados durante
la operación normal para reducir consumo de CPU, RAM o I/O.

Prometheus y OmniRoute ya no pertenecen al grupo bajo demanda:

- Prometheus es permanente para conservar métricas históricas.
- OmniRoute es permanente porque sirve como gateway de IA para Hermes y clientes
  OpenAI-compatible.

## Clasificación actual

| Componente | Estado habitual |
|---|---|
| Immich | Bajo demanda |
| Jellyfin | Bajo demanda |
| Grafana | Bajo demanda |
| cAdvisor | Bajo demanda |
| Home Assistant VM 300 | En retirada, pendiente de eliminación futura |
| Prometheus | Siempre activo, no crítico |
| Node Exporter | Siempre activo, no crítico |
| OmniRoute | Crítico, siempre activo |
| Hermes VM 400 | Crítica, siempre activa |

Ponga los monitores correspondientes de Uptime Kuma en mantenimiento cuando un
servicio esté apagado intencionalmente. No elimine monitores, DNS ni TLS.

## Multimedia bajo demanda

### Apagado planificado

Si desea una última copia antes del apagado, ejecute primero en `docker01`:

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
```

Detenga los stacks en `docker01`:

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

Use `stop`, no `down --volumes`. Los volúmenes y datos persistentes deben
conservarse.

### Encendido planificado

Primero confirme en `docker01` que los discos necesarios están montados:

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

Valide:

```bash
docker inspect immich-server jellyfin \
  --format 'name={{.Name}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'

curl --silent --show-error \
  https://immich.lab/api/server/ping

curl --silent --show-error --output /dev/null \
  --write-out 'Jellyfin HTTP %{http_code}\n' \
  https://jellyfin.lab/health
```

## Observabilidad bajo demanda

Prometheus y Node Exporter permanecen activos. Grafana y cAdvisor se encienden
solo cuando se requiere análisis visual o métricas detalladas de contenedores.

El target `cadvisor:8080` permanece en Prometheus. Cuando cAdvisor esté apagado
intencionalmente, Prometheus mostrará ese target `DOWN`; esa condición no debe
confundirse con una falla de Prometheus.

### Encender Grafana y cAdvisor

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  start

docker compose \
  --project-directory /opt/quesadalab/stacks/grafana \
  --env-file /opt/quesadalab/stacks/grafana/.env \
  --file /opt/quesadalab/stacks/grafana/docker-compose.yml \
  start
```

Valide:

```bash
curl --silent --show-error --output /dev/null \
  --write-out 'Prometheus HTTP %{http_code}\n' \
  http://prometheus.lab/-/ready

curl --silent --show-error --output /dev/null \
  --write-out 'Grafana HTTP %{http_code}\n' \
  http://grafana.lab/login
```

### Apagar Grafana y cAdvisor

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/grafana \
  --env-file /opt/quesadalab/stacks/grafana/.env \
  --file /opt/quesadalab/stacks/grafana/docker-compose.yml \
  stop --timeout 60

docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  stop --timeout 60
```

No detenga Prometheus como parte de este flujo.

## Home Assistant en retirada

VM 300 `homeassistant` se conserva temporalmente para referencia y posible
recuperación, pero está en retirada y pendiente de eliminación futura.

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

Mantenga `onboot=0`. No elimine la VM, DNS, TLS ni configuración hasta que la
retirada sea aprobada explícitamente.
