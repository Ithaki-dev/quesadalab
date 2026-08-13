# Hermes Agent Master Brief

Use this document as the canonical operating context for Hermes-related work in QuesadaLab.

## Mission

Hermes is the QuesadaLab assistant. It runs in its own Debian VM and uses external model providers. It is responsible for chat, workflow automation, scheduled tasks, and controlled integrations with messaging platforms.

## Hard boundaries

- Do not expose Hermes publicly through Cloudflare Tunnel.
- Do not expose SSH to the Internet.
- Do not assume a provider, model, or route is active; verify the live configuration first.
- Do not print, log, commit, or paste secrets, tokens, app passwords, sessions, memories, or backups.
- Do not modify `.env`, gateway credentials, or VM archives without a backup.
- Do not enable unrestricted user access on messaging platforms.

## Infrastructure

- Proxmox VM: `400`
- VM name: `agent01`
- Hostname: `agent01`
- LAN address: `192.168.1.60`
- Internal names: `agent01.lab`, `hermes.lab`
- OS: Debian 13
- Resources: 4 vCPU, 4 GiB RAM, 64 GiB disk
- Emergency swap: 2 GiB
- Guest integration: QEMU Guest Agent and periodic trim
- User data root: `/home/hermes/.hermes`

## Runtime model

Hermes runs as the `hermes` user and uses a user-level gateway service:

- `hermes-gateway.service`
- systemd linger is enabled

Relevant local paths:

- `/home/hermes/.hermes/config.yaml`
- `/home/hermes/.hermes/.env`
- `/home/hermes/.hermes/hermes-agent`
- `/home/hermes/.hermes/logs`
- `/home/hermes/.hermes/sessions`
- `/home/hermes/.hermes/memories`
- `/home/hermes/.hermes/cron`

## Provider policy

The default provider is external and must be checked in the live config before any model work. The repo history has included OpenRouter and OmniRoute during experiments, so do not assume the current provider from memory.

Rules:

- Verify `config.yaml` and `.env` before changing anything.
- Use the least privilege key required for the workflow.
- Treat provider keys as confidential.
- Never expose the provider credential directly to other systems.

## Messaging platforms

Hermes can integrate with:

- Discord
- Telegram
- Gmail via IMAP and SMTP

Platform rules:

- Discord should use least-privilege intents and allowlists.
- Telegram should be restricted to the owner and a home chat.
- Gmail should use an application password, not a normal account password.
- Do not enable open access for any platform.

## Operational checks

Use these checks before changing the gateway or provider:

```bash
hermes --version
hermes doctor
systemctl --user is-active hermes-gateway.service
systemctl --user status hermes-gateway.service --no-pager
journalctl --user -u hermes-gateway.service -n 100 --no-pager
free -h
df -hT /
```

From Proxmox:

```bash
qm status 400
qm agent 400 ping
ping -c 3 192.168.1.60
```

## Troubleshooting order

1. Confirm the VM is running and reachable.
2. Confirm `hermes-gateway.service` is active.
3. Inspect the live provider configuration.
4. Inspect the gateway logs for auth, model, or tool failures.
5. Check DNS and TLS only if the failure looks network-related.
6. Back up before changing credentials, provider config, or gateway state.

## Backups and restore

Hermes VM backups contain secrets and are confidential.

- Backup runbook: [`../../runbooks/hermes-backup.md`](../../runbooks/hermes-backup.md)
- Restore runbook: [`../../runbooks/hermes-restore.md`](../../runbooks/hermes-restore.md)

## Recommended workflow for the agent

When asked to change Hermes:

1. Read `config.yaml` and `.env`.
2. Confirm gateway status.
3. Confirm network reachability and TLS.
4. Make a backup if credentials or provider settings may change.
5. Change only the minimum required setting.
6. Validate with a no-secret check and a real end-to-end test.
7. Record the final state in documentation.

