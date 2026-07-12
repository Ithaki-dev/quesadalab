# Docker Engine Design

## Objective

Provide an isolated and reproducible container platform for self-hosted services.

## Why a dedicated VM?

Docker is intentionally isolated from the Proxmox host.

Advantages:

- Better security
- Easier backups
- Independent upgrades
- Snapshots before major changes
- Clean separation between hypervisor and workloads

## Architecture

```text
Proxmox VE
      │
      │
Debian 13 VM
      │
Docker Engine
      │
Containers
```