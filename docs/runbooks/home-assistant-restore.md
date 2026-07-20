# Home Assistant restore

Choose the least invasive recovery method that addresses the failure.

## Native restore

Use an encrypted native Home Assistant backup when HAOS still boots or during a
fresh HAOS onboarding. Supply the matching encryption key from the emergency
kit, restore the selected set, and allow Supervisor and Core to restart.

Afterward, validate:

- administrator login;
- integrations, automations and add-ons;
- `https://homeassistant.lab` through Traefik;
- the Uptime Kuma monitor;
- a new manual native backup.

## Full VM restore

A Proxmox restore replaces VM state and is destructive if performed over VM
300. Schedule downtime, confirm the exact archive, and preserve the current VM
until the recovered copy has been validated.

List available archives:

```bash
pvesm list qlab-usb-backup --vmid 300
findmnt /mnt/quesadalab-backup
df -hT /mnt/quesadalab-backup
```

The preferred rehearsal is to restore to an unused temporary VMID on an
isolated network. Do not boot it on the production bridge with the same MAC or
IP as VM 300.

For an actual disaster recovery, use the Proxmox restore workflow after
explicit approval. Preserve these production identities:

- VMID `300` and name `homeassistant`;
- MAC `BC:24:11:AB:AA:A3`;
- DHCP reservation `192.168.1.40`;
- OVMF/Q35 configuration and QEMU Guest Agent;
- DNS `homeassistant.lab -> 192.168.1.30` for Traefik.

## Post-restore validation

```bash
qm status 300
qm agent 300 ping
getent ahostsv4 homeassistant.lab
curl --silent --show-error --output /dev/null \
  --write-out 'Frontend HTTPS %{http_code}\n' \
  https://homeassistant.lab/
curl --silent --show-error --output /dev/null \
  --write-out 'Backend HTTP %{http_code}\n' \
  http://192.168.1.40:8123/
```

Confirm the certificate hostname, Traefik routing, integrations, automations,
Kuma status and both backup schedules before declaring recovery complete.
