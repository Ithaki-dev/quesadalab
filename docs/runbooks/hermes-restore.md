# Hermes Agent restore

A VM restore can expose live API credentials and bot tokens. Perform it only
from trusted storage and keep the recovered VM isolated until identities and
credentials are reviewed.

## Preparation

```bash
pvesm list qlab-usb-backup --vmid 400
findmnt /mnt/quesadalab-backup
df -hT /mnt/quesadalab-backup
```

Prefer restoring to an unused temporary VMID on an isolated bridge. Do not
start a clone on the production LAN with the same MAC address or IP.

## Production identity

An in-place disaster recovery must preserve:

- VMID `400`, name `agent01` and address `192.168.1.60`;
- DNS names `agent01.lab` and `hermes.lab`;
- QEMU Guest Agent, discard and periodic trim;
- 4 vCPU, 4 GiB RAM, 64 GiB disk and 2 GiB swap;
- SSH key authentication for the `hermes` user.

## Post-restore validation

From Proxmox:

```bash
qm status 400
qm agent 400 ping
ping -c 3 192.168.1.60
```

Inside the guest:

```bash
hermes --version
hermes doctor
systemctl --user is-active hermes-gateway.service
journalctl --user -u hermes-gateway.service -n 100 --no-pager
free -h
/sbin/swapon --show
df -hT /
```

Validate Discord, Telegram and email separately without printing tokens. If
the archive was exposed outside trusted storage, rotate the OpenRouter key,
Discord and Telegram bot tokens, Gmail app password and any other credential
stored in `.env`.
