# cAdvisor

cAdvisor exports Docker container resource metrics to Prometheus. It belongs
to the on-demand monitoring group together with Prometheus and Grafana.

## Runtime

- Stack: `/opt/quesadalab/stacks/cadvisor`
- Container: `cadvisor`
- Expected state: stopped when monitoring is not needed
- Persistent application data: none

The container requires read-only access to host and Docker runtime paths.
Those mounts are privileged observation surfaces and must not be broadened.

## Lifecycle

Start cAdvisor before Prometheus:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  start
```

Stop it after Prometheus:

```bash
docker compose \
  --project-directory /opt/quesadalab/stacks/cadvisor \
  --file /opt/quesadalab/stacks/cadvisor/docker-compose.yml \
  stop --timeout 60
```

See
[`../../runbooks/optional-services-lifecycle.md`](../../runbooks/optional-services-lifecycle.md)
for the complete monitoring sequence.
