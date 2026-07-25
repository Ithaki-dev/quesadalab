# Hermes Agent backup

Hermes is protected as Proxmox VM 400. The archive includes the operating
system, agent code, configuration, memories, sessions and credentials.
Therefore every backup is confidential.

## Scheduled job

The Proxmox job `hermes-daily` runs at 01:30 using snapshot mode, Zstandard
compression and USB storage `qlab-usb-backup`. Inspect the live job rather than
assuming it is enabled:

```bash
pvesh get /cluster/backup/hermes-daily --output-format json-pretty
pvesm list qlab-usb-backup --vmid 400
findmnt /mnt/quesadalab-backup
```

The intended retention is last 3, weekly 4 and monthly 3.

## Manual backup

Before provider changes, gateway upgrades or major tool configuration:

```bash
qm status 400
qm agent 400 ping
findmnt /mnt/quesadalab-backup

vzdump 400 \
  --storage qlab-usb-backup \
  --mode snapshot \
  --compress zstd \
  --ionice 7 \
  --remove 0 \
  --notes-template 'QuesadaLab Hermes Agent manual backup'
```

Verify the newest archive:

```bash
latest="$(find /mnt/quesadalab-backup/dump \
  -maxdepth 1 -type f -name 'vzdump-qemu-400-*.vma.zst' \
  -printf '%T@ %p\n' |
  sort -nr |
  awk 'NR == 1 {$1=""; sub(/^ /, ""); print}')"

zstd --test "$latest"
qm status 400
qm agent 400 ping
```

Never upload the archive to a public file share or attach it to an issue. A
successful compressed-stream test verifies transport integrity, not a full
application restore; perform periodic isolated restore rehearsals.
