# Node Exporter

Node Exporter exposes lightweight host metrics from `docker01` for Prometheus.
It remains running even when the heavier monitoring group is stopped.

## Runtime

- Stack: `/opt/quesadalab/stacks/node-exporter`
- Container: `node-exporter`
- Expected state: running
- Consumer: Prometheus when the monitoring group is enabled

## Validation

```bash
docker inspect node-exporter \
  --format 'status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}}'

docker exec node-exporter wget -qO- \
  http://127.0.0.1:9100/metrics |
head
```

An interruption while Prometheus is stopped is expected to create a gap; Node
Exporter itself does not retain samples.
