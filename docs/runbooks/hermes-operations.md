# Hermes Operations

This runbook covers routine administration of Hermes on `agent01`.

## Scope

- Start, stop, and inspect the gateway.
- Validate provider configuration.
- Check messaging platform integrations.
- Confirm host and guest health.
- Recover from misconfiguration without exposing secrets.

## Host identity

- VM: `400`
- Hostname: `agent01`
- LAN IP: `192.168.1.60`

## Routine health checks

From inside the VM:

```bash
hermes --version
hermes doctor
systemctl --user is-active hermes-gateway.service
systemctl --user status hermes-gateway.service --no-pager
journalctl --user -u hermes-gateway.service -n 100 --no-pager
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

## Gateway control

```bash
hermes gateway status
hermes gateway start
hermes gateway stop
hermes gateway restart
```

If the service is managed by systemd, check:

```bash
systemctl --user status hermes-gateway.service --no-pager
systemctl --user is-active hermes-gateway.service
loginctl show-user hermes --property=Linger
```

## Provider validation

Before changing models or routing:

```bash
grep -q '^OPENROUTER_API_KEY=' "$HOME/.hermes/.env" &&
  echo '[OK] Provider key present'

grep -nE '^(provider:|model:|  default:|  base_url:)' \
  "$HOME/.hermes/config.yaml"
```

Never print the value of `.env`.

## Messaging validation

Discord:

- Confirm the bot token is present in the private environment.
- Verify message-content intent only if required by the use case.
- Use allowlists for users, roles, or channels.

Telegram:

- Confirm the bot token is present.
- Keep access restricted to the owner or approved users.

Email:

- Confirm IMAP and SMTP credentials are set.
- Use an application password for Gmail.

## Backup before change

If a change touches provider credentials, `.env`, or gateway behavior, create a backup first.

Use the backup runbook:

- [`hermes-backup.md`](./hermes-backup.md)

## Recovery

If Hermes stops responding:

1. Check VM health from Proxmox.
2. Check `hermes-gateway.service`.
3. Read the last 100 lines of the journal.
4. Verify the provider settings in `config.yaml` and `.env`.
5. Validate platform credentials one by one.
6. Restore from backup only if the config is irreparably corrupted.

Use the restore runbook:

- [`hermes-restore.md`](./hermes-restore.md)

