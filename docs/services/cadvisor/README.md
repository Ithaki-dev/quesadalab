# cAdvisor

cAdvisor exports Docker container resource metrics to Prometheus. It remains
an on-demand service. Prometheus is permanent; Grafana remains on demand.

## Runtime

- Stack: `/opt/quesadalab/stacks/cadvisor`
- Container: `cadvisor`
- Expected state: stopped when detailed container metrics are not needed
- Persistent application data: none

The container requires read-only access to host and Docker runtime paths.
Those mounts are privileged observation surfaces and must not be broadened.

Prometheus keeps the `cadvisor:8080` target configured. When cAdvisor is
intentionally stopped, that target appears `DOWN`; treat it as expected
on-demand state, not as a Prometheus failure.

## Lifecycle

Start cAdvisor when detailed container metrics are needed:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  start
```

Stop it after the diagnostic window:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  stop --timeout 60
```

See
[`../../runbooks/optional-services-lifecycle.md`](../../runbooks/optional-services-lifecycle.md)
for the complete monitoring sequence.
