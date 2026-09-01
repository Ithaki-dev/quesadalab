# Prometheus configuration

## Managed files

Prometheus uses:

```text
/opt/quesadalab/stacks/prometheus/docker-compose.yml
/opt/quesadalab/config/prometheus/prometheus.yml
/opt/quesadalab/data/prometheus
```

## Compose runtime

The service must keep:

```yaml
restart: unless-stopped
```

The command arguments include:

```yaml
- --config.file=/etc/prometheus/prometheus.yml
- --storage.tsdb.path=/prometheus
- --storage.tsdb.retention.time=30d
- --storage.tsdb.retention.size=5GB
- --web.enable-lifecycle
```

The 30-day retention provides historical metrics. The 5 GB size cap limits
storage growth.

## Scrape configuration

The managed Prometheus config lives at:

```text
/opt/quesadalab/config/prometheus/prometheus.yml
```

Expected scrape targets:

- `prometheus:9090`
- `node-exporter:9100`
- `cadvisor:8080`

cAdvisor is under demand. Its target may be `DOWN` when the container is
intentionally stopped.

## Docker networks

Prometheus uses:

- `proxy` for Traefik exposure.
- `monitoring` for communication with exporters.

## Health endpoints

```text
http://prometheus.lab/-/ready
http://prometheus.lab/-/healthy
http://prometheus.lab/metrics
```
