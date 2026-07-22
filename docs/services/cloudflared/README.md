# Cloudflare Tunnel

QuesadaLab runs a remotely managed Cloudflare Tunnel connector on `docker01`.
The connector provides outbound-only access from Cloudflare to explicitly
published services; no inbound router port forwarding is required.

## Runtime

- Stack: `/opt/quesadalab/stacks/cloudflared`
- Container: `cloudflared`
- Image: `cloudflare/cloudflared:2026.7.2`
- Network: external Docker network `proxy`
- Tunnel token: `/opt/quesadalab/data/cloudflared/tunnel-token`

The token is runtime-only, owned by `root:root`, mode `0600`, and must never be
committed to Git, pasted into issues, or exposed through command arguments.
Compose mounts it through `/run/secrets/tunnel-token`, and cloudflared reads it
with `--token-file`.

## Initial publication

The first public application is `cloud.ithakidev.com`, routed to
`http://homepage:3000`. A Cloudflare Access self-hosted application and its
allow policy must exist before the public hostname is added to the tunnel.

## Validation

```bash
docker inspect cloudflared \
  --format 'status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}}'

docker logs --tail 100 cloudflared
```

Validate in Cloudflare that the tunnel is `Healthy`, then test the public
hostname in a private browser session. An unauthenticated request must be sent
to Cloudflare Access rather than directly to Homepage.

## Security boundary

- Do not publish Proxmox, SSH, or Hermes directly through a public hostname.
- Add each future application with its own Access policy.
- Rotate the tunnel token in Cloudflare if it is ever disclosed.
- VM and USB backups containing the token are confidential.
