# ADR-004

## Title

Docker Engine hosted in a dedicated Debian virtual machine.

## Status

Accepted

## Context

Several services will be deployed using Docker Compose.

Keeping Docker inside a dedicated VM provides isolation from the Proxmox host while simplifying backup, maintenance and recovery.

## Decision

Deploy Docker Engine on a Debian 13 virtual machine.

Specifications

- Debian 13
- 4 vCPU
- 6 GB RAM
- 80 GB SSD
- QEMU Guest Agent
- Static IP: 192.168.1.30

## Current implementation note

This ADR records the original accepted VM sizing. The current operational
configuration for VM 200 `docker01` is 4 vCPU, 8 GiB RAM and 80 GB system disk.
The RAM increase supports the present always-on service baseline, including
Prometheus and OmniRoute.

## Consequences

Advantages

- Better isolation
- Easy snapshots
- Independent upgrades
- Clean Docker environment
