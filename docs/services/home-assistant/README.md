# Home Assistant

Home Assistant is the home-automation platform for QuesadaLab. It runs as a
dedicated Home Assistant OS virtual machine instead of a Docker container so
that Supervisor, add-ons, managed updates and native backups remain available.

## Production design

| Component | Value |
|---|---|
| Proxmox VM | `300` (`homeassistant`) |
| Operating system | Home Assistant OS 17.3 (OVA) |
| Resources | 2 vCPU, 2 GiB RAM, 32 GiB disk |
| Firmware and machine | OVMF, Secure Boot disabled, Q35 |
| Guest integration | QEMU Guest Agent enabled |
| Backend address | `192.168.1.40:8123` |
| User-facing URL | `https://homeassistant.lab` |
| Reverse proxy | Traefik on `192.168.1.30` |
| TLS certificate | Dedicated QuesadaLab PKI certificate, serial `1005` |
| Normal state | Stopped, `onboot=0` |

OpenWrt reserves `192.168.1.40` for MAC address
`BC:24:11:AB:AA:A3`. AdGuard resolves `homeassistant.lab` to Traefik at
`192.168.1.30`; the reverse proxy then forwards requests to the HAOS backend.
Do not publish port 8123 through the Internet.

## Reverse-proxy trust

The HAOS configuration at
`/mnt/data/supervisor/homeassistant/configuration.yaml` contains:

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.1.30
```

Only the Traefik host is trusted. Validate changes with `ha core check` before
restarting Home Assistant Core.

Traefik uses the file-provider configuration
`/opt/quesadalab/data/traefik/dynamic/homeassistant.yml` on `docker01` and
routes the service through the `websecure` entrypoint with the `lan-only` and
`security-headers` middlewares.

## Internal PKI

The dedicated certificate has serial `1005`, SAN `homeassistant.lab`, and is
signed by the QuesadaLab Intermediate CA. Its private key remains only under the
protected PKI and Traefik TLS directories on `docker01`.

Proxmox trusts only the public QuesadaLab Root CA installed at
`/usr/local/share/ca-certificates/quesadalab-root-ca.crt`. Its SHA-256 file hash
is `73e9b30451247de5ce903bcacec89fe38d940f16db5712f437e9bae08a0929e7`.
This allows host-side checks without disabling certificate verification. Never
copy the root or intermediate private keys to Proxmox.

## On-demand lifecycle

VM 300 remains stopped to reserve memory for Hermes. Start it only when home
automation work is required:

```bash
qm start 300
qm agent 300 ping
```

Before stopping it, use the Home Assistant UI to shut down the host or run an
approved guest shutdown. Confirm `status: stopped`; do not use `qm stop` except
for recovery from an unresponsive guest.

The scheduled Proxmox backup job and Uptime Kuma monitor remain disabled or
paused while the VM is intentionally offline. See
[`../../runbooks/optional-services-lifecycle.md`](../../runbooks/optional-services-lifecycle.md).

## Validation while running

On Proxmox:

```bash
qm status 300
qm agent 300 ping
curl --silent --show-error --output /dev/null \
  --write-out 'Home Assistant HTTPS %{http_code}\n' \
  https://homeassistant.lab/
curl --silent --show-error --output /dev/null \
  --write-out 'HAOS backend HTTP %{http_code}\n' \
  http://192.168.1.40:8123/
```

The expected result while VM 300 is running is HTTP 200 for both paths. HTTPS
must validate with the system trust store; do not use `--insecure`.

## Monitoring

The Uptime Kuma monitor for `https://homeassistant.lab/` is paused while VM 300
is stopped. When enabled, it accepts status codes 200-299 with TLS verification
and covers DNS, the internal PKI, Traefik and Home Assistant.

## Backup and recovery

Create an encrypted native HAOS backup before updates or important
configuration changes. Keep its emergency kit outside the server.

The Proxmox job `homeassistant-daily` remains configured but disabled while the
VM is on demand. Create an approved manual USB backup before extended
shutdowns and before reallocating resources. See
[`../../runbooks/home-assistant-backup.md`](../../runbooks/home-assistant-backup.md)
and
[`../../runbooks/home-assistant-restore.md`](../../runbooks/home-assistant-restore.md).
