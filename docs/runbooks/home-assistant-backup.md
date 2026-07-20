# Home Assistant backup

Home Assistant uses two independent protection layers: encrypted native HAOS
backups for application-level recovery and full Proxmox VM backups for disaster
recovery.

## Native HAOS backup

The production schedule is:

- daily at 00:15;
- retain seven backups;
- create a backup before Home Assistant updates;
- include configuration, history, add-ons and application state;
- exclude replaceable media and share data;
- encrypt the backup and keep the emergency kit outside QuesadaLab.

Run a manual native backup before significant integration, add-on or
configuration changes. Never store the only copy of the emergency kit inside
VM 300 or on the same USB backup disk.

## Proxmox VM backup

The cluster backup job `homeassistant-daily` protects VM 300 with:

| Setting | Value |
|---|---|
| Schedule | 00:45 daily |
| Storage | `qlab-usb-backup` |
| Mode | Snapshot |
| Compression | Zstandard |
| I/O priority | 7 |
| Retention | last 3, weekly 4, monthly 3 |

Inspect the job and destination:

```bash
pvesh get /cluster/backup/homeassistant-daily --output-format json-pretty
findmnt /mnt/quesadalab-backup
df -hT /mnt/quesadalab-backup
pvesm list qlab-usb-backup --vmid 300
```

Create an approved manual backup when required:

```bash
vzdump 300 \
  --storage qlab-usb-backup \
  --mode snapshot \
  --compress zstd \
  --ionice 7 \
  --remove 0 \
  --notes-template 'QuesadaLab Home Assistant OS manual backup'
```

Verify the latest archive without restoring it:

```bash
latest="$(find /mnt/quesadalab-backup/dump \
  -maxdepth 1 -type f -name 'vzdump-qemu-300-*.vma.zst' \
  -printf '%T@ %p\n' | sort -nr | awk 'NR == 1 {$1=""; sub(/^ /, ""); print}')"

zstd --test "$latest"
qm status 300
curl --silent --show-error --output /dev/null \
  --write-out 'Home Assistant HTTP %{http_code}\n' \
  https://homeassistant.lab/
```

Review scheduled job history after its first automatic execution and monitor
the USB filesystem for capacity and kernel I/O errors.
