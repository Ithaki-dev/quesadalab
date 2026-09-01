# Prometheus

Prometheus is the permanent metrics store for QuesadaLab. It collects historical
metrics from always-on exporters and exposes data for Grafana and future
consumers such as Quesada-Mobile.

## Service information

| Parameter | Value |
|---|---|
| Service | Prometheus |
| Container | `prometheus` |
| Image | `prom/prometheus:latest` |
| Internal port | `9090` |
| Access | `http://prometheus.lab` |
| Proxy | Traefik |
| Docker networks | `proxy`, `monitoring` |
| State | `/opt/quesadalab/data/prometheus` |
| Normal state | Running |
| Restart policy | `unless-stopped` |

## Retention

Prometheus keeps historical data with both time and size controls:

- `--storage.tsdb.retention.time=30d`
- `--storage.tsdb.retention.size=5GB`

The size cap prevents uncontrolled TSDB growth while preserving recent history.
Do not delete `/opt/quesadalab/data/prometheus` during normal maintenance.

## Scrape targets

Prometheus collects:

- Prometheus self-metrics.
- Node Exporter on the always-on monitoring path.
- cAdvisor when cAdvisor is intentionally started under demand.

The cAdvisor target remains configured even though cAdvisor is not permanent.
When cAdvisor is stopped intentionally, Prometheus will show that target as
`DOWN`. Treat that as expected service lifecycle state, not as a Prometheus
failure.

## Grafana relationship

Grafana remains under demand. It consumes Prometheus when Grafana is running,
but Prometheus does not depend on Grafana.

## Validation

```bash
docker inspect prometheus \
  --format 'name={{.Name}} status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}} image={{.Config.Image}}'

curl --silent --show-error --output /dev/null \
  --write-out 'Prometheus ready HTTP %{http_code}\n' \
  http://prometheus.lab/-/ready
```

## Quesada-Mobile

Quesada-Mobile is planned, not operational. It may consume Prometheus for
historical data in the future, but it must not depend exclusively on Prometheus
for real-time operational state.
