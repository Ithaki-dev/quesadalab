# Proxmox VE

Proxmox VE is the QuesadaLab hypervisor on node `quesada`.

## Role

- runs the Docker, Home Assistant and Hermes virtual machines;
- exposes `local` and `local-lvm` storage;
- mounts the USB backup storage as `qlab-usb-backup`;
- runs scheduled `vzdump` jobs;
- provides the QEMU Guest Agent control plane.

## Production virtual machines

| VMID | Name | Expected state |
|---|---|---|
| 200 | `docker01` | running, `onboot=1` |
| 300 | `homeassistant` | stopped, `onboot=0` |
| 400 | `agent01` | running, `onboot=1` |

## Routine validation

```bash
hostname
pveversion
qm list
pvesm status
free -h
df -hT /
findmnt /mnt/quesadalab-backup
pvesh get /cluster/backup --output-format json-pretty
```

Do not start VM 300 or raise VM memory allocations without checking host
`MemAvailable`, swap use and the total configured memory of running VMs.

The web UI, SSH and API remain LAN-only. Remote access to Homepage through
Cloudflare Access is not administrative access to Proxmox.
