# Instalación de Prometheus

Prometheus es un servicio permanente de QuesadaLab. No pertenece al grupo bajo
demanda.

## Estructura

```bash
mkdir -p /opt/quesadalab/stacks/prometheus
mkdir -p /opt/quesadalab/config/prometheus
mkdir -p /opt/quesadalab/data/prometheus
```

## Docker Compose

Ubicación:

```text
/opt/quesadalab/stacks/prometheus/docker-compose.yml
```

La configuración debe conservar:

- `restart: unless-stopped`
- almacenamiento persistente en `/opt/quesadalab/data/prometheus`
- `--storage.tsdb.retention.time=30d`
- `--storage.tsdb.retention.size=5GB`

Validar:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/prometheus \
  --file /opt/quesadalab/stacks/prometheus/docker-compose.yml \
  config --quiet
```

Desplegar:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/prometheus \
  --file /opt/quesadalab/stacks/prometheus/docker-compose.yml \
  up --detach
```

Verificar:

```bash
curl --silent --show-error --fail \
  http://prometheus.lab/-/ready
```

## Configuración

Archivo:

```text
/opt/quesadalab/config/prometheus/prometheus.yml
```

Validar configuración:

```bash
docker run --rm \
  -v /opt/quesadalab/config/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro \
  prom/prometheus \
  promtool check config /etc/prometheus/prometheus.yml
```

## Targets

Prometheus mantiene el target de cAdvisor configurado. Cuando cAdvisor esté
apagado intencionalmente, ese target aparecerá `DOWN`; esa condición representa
su ciclo de vida bajo demanda, no una falla de Prometheus.
