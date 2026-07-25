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

The token is runtime-only and must never be committed to Git, pasted into
issues, or exposed through command arguments. The host file must be readable
only by root and the numeric UID used by the container. Compose mounts it
read-only through `/run/secrets/tunnel-token`, and cloudflared reads it with
`--token-file`.

Validate the effective ownership and mount instead of assuming them:

```bash
stat -c '%A %U:%G %n' \
  /opt/quesadalab/data/cloudflared/tunnel-token

docker inspect cloudflared \
  --format '{{range .Mounts}}{{println .Destination .RW}}{{end}}'
```

## Published application

`cloud.ithakidev.com` routes to `http://homepage:3000`. A Cloudflare Access
self-hosted application and its allow policy protect the hostname before
traffic reaches the tunnel.

This is a published-application route, not a CIDR private-network route.
Cloudflare automatically manages the proxied public DNS record.

## Validation

```bash
docker inspect cloudflared \
  --format 'status={{.State.Status}} restart={{.HostConfig.RestartPolicy.Name}}'

docker logs --tail 100 cloudflared
```

Validate in Cloudflare that the tunnel is `Healthy`, then test the public
hostname in a private browser session. An unauthenticated request must be sent
to Cloudflare Access rather than directly to Homepage.

```bash
curl --silent --show-error --output /dev/null \
  --write-out 'Unauthenticated HTTPS %{http_code}\n' \
  https://cloud.ithakidev.com/
```

The expected unauthenticated result is a redirect to the Cloudflare Access
login. Do not use `--location` for this check.

If public Cloudflare DNS resolves but AdGuard returns no answer, configure a
domain-specific encrypted upstream for `ithakidev.com`, flush the resolver
cache and retest. Do not create a second manual A or CNAME record.

## Security boundary

- Do not publish Proxmox, SSH, or Hermes directly through a public hostname.
- Add each future application with its own Access policy.
- Rotate the tunnel token in Cloudflare if it is ever disclosed.
- VM and USB backups containing the token are confidential.
