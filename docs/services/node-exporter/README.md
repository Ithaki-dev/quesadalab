# Node Exporter

Node Exporter exposes lightweight host metrics from `docker01` for Prometheus.
It remains running permanently. Prometheus is also permanent and scrapes Node
Exporter for host-level metrics.

## Runtime

- Stack: `/opt/quesadalab/stacks/node-exporter`
- Container: `node-exporter`
- Expected state: running
- Consumer: Prometheus

## Validation

```bash
docker inspect node-exporter \
  --format 'status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}}'

docker exec node-exporter wget -qO- \
  http://127.0.0.1:9100/metrics |
head
```

Node Exporter does not retain samples. Prometheus is responsible for historical
retention and currently keeps 30 days with a 5 GB storage cap.
