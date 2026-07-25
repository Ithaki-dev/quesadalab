# Hermes Agent

Hermes Agent is the QuesadaLab assistant. It runs in its own Debian virtual
machine and uses an external model provider; no model is hosted locally.

## Production profile

| Component | Value |
|---|---|
| Proxmox VM | `400` (`agent01`) |
| Operating system | Debian 13 (Trixie) |
| Address | `192.168.1.60` |
| Internal names | `agent01.lab`, `hermes.lab` |
| Resources | 4 vCPU, 4 GiB RAM, 64 GiB disk |
| Emergency swap | 2 GiB, `vm.swappiness=10` |
| Guest integration | QEMU Guest Agent and periodic trim |
| Hermes data | `/home/hermes/.hermes` |
| Default provider | OpenRouter |
| Default model | `openrouter/free` |
| Gateway service | User unit `hermes-gateway.service` with linger |

The VM starts with Proxmox (`onboot=1`). Its resource profile assumes Home
Assistant VM 300 remains stopped. Recalculate host capacity before starting
additional VMs or increasing memory.

## Files and permissions

| Path | Purpose | Required protection |
|---|---|---|
| `/home/hermes/.hermes/config.yaml` | Model, tools and gateway configuration | owner `hermes`, mode `0600` |
| `/home/hermes/.hermes/.env` | Provider and platform credentials | owner `hermes`, mode `0600` |
| `/home/hermes/.hermes/hermes-agent` | Installed Hermes source and virtual environment | owner `hermes` |
| `/home/hermes/.hermes/cron` | Scheduled agent tasks | private |
| `/home/hermes/.hermes/sessions` | Conversation state | private |
| `/home/hermes/.hermes/memories` | Persistent memory | private |
| `/home/hermes/.hermes/logs` | Runtime logs | private |

Never commit `.env`, API keys, bot tokens, Gmail app passwords, sessions,
memories or VM archives. Proxmox backups of VM 400 contain these secrets and
must be treated as confidential.

## Provider policy

Hermes uses a dedicated OpenRouter key, not a ChatGPT Plus subscription or an
OpenAI account token. The key is restricted by an OpenRouter guardrail and the
default model is the free router.

Validate authentication without printing the key:

```bash
grep -q '^OPENROUTER_API_KEY=' "$HOME/.hermes/.env" &&
  echo '[OK] OpenRouter key is configured'

grep -nE '^(model:|  default:|  provider:)' \
  "$HOME/.hermes/config.yaml"

hermes doctor
```

Free endpoints may change, be rate limited or process data under different
provider policies. Do not send passwords, private keys, recovery codes,
personal documents or unredacted infrastructure secrets to the model.

## Messaging gateway

The gateway is configured for:

- Discord, restricted by user and channel allowlists;
- Telegram, restricted to the owner and using the owner chat as home channel;
- Gmail through IMAP and SMTP with a dedicated application password.

The exact account IDs and all tokens remain only in the private environment.
Do not enable `ALLOW_ALL_USERS` for any platform.

Useful commands:

```bash
hermes gateway status
hermes gateway restart
journalctl --user -u hermes-gateway.service -n 100 --no-pager
loginctl show-user hermes --property=Linger
```

The Discord application requires the message-content intent. Presence and
member intents should remain disabled unless a documented feature requires
them. Platform permissions must follow least privilege.

## Tool boundary

Tools are opt-in. Enable only capabilities needed for an approved workflow.
Terminal, file, browser and automation tools can change external systems, so
the agent must not receive unrestricted credentials for Proxmox, Docker,
Cloudflare or the router.

Current boundaries:

- SSH is available only on the LAN with key authentication;
- root login and password authentication are disabled;
- Hermes is not published by Traefik or Cloudflare Tunnel;
- Home Assistant control is not enabled;
- no direct Proxmox or Docker administrative credential is stored for Hermes.

## Health checks

From `agent01`:

```bash
hermes --version
hermes doctor
systemctl --user is-active hermes-gateway.service
free -h
/sbin/swapon --show
df -hT /
```

From Proxmox:

```bash
qm status 400
qm agent 400 ping
ping -c 3 192.168.1.60
```

See the backup and recovery runbooks:

- [`../../runbooks/hermes-backup.md`](../../runbooks/hermes-backup.md)
- [`../../runbooks/hermes-restore.md`](../../runbooks/hermes-restore.md)
