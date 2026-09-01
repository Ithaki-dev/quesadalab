# Grafana

Grafana is the visualization layer for QuesadaLab metrics. It uses Prometheus as
its datasource to inspect host, container and service trends.

## Service information

| Parameter | Value |
|---|---|
| Service | Grafana |
| Container | `grafana` |
| Image | `grafana/grafana:latest` |
| Internal port | `3000` |
| Access | `http://grafana.lab` |
| Proxy | Traefik |
| Docker networks | `proxy`, `monitoring` |
| State | `/opt/quesadalab/data/grafana` |
| Normal state | Stopped until needed |

## Lifecycle

Grafana remains under demand. Do not make it part of the permanent service
baseline unless a separate resource review approves that change.

Prometheus remains running while Grafana is stopped, so historical metrics keep
accumulating.

Start:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/grafana \
  --env-file /opt/quesadalab/stacks/grafana/.env \
  --file /opt/quesadalab/stacks/grafana/docker-compose.yml \
  start
```

Stop:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/grafana \
  --env-file /opt/quesadalab/stacks/grafana/.env \
  --file /opt/quesadalab/stacks/grafana/docker-compose.yml \
  stop --timeout 60
```

## Datasource

Grafana uses Prometheus:

```text
http://prometheus:9090
```

See [`../prometheus/README.md`](../prometheus/README.md).
