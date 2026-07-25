# Documentation audit — July 2026

## Scope

This audit compared tracked documentation with the deployed stacks, scripts,
systemd units and validated production state recorded during implementation.
Private untracked workspaces and credential files were excluded.

## Findings resolved

- added the Hermes VM, provider, gateway, security and recovery documentation;
- added Proxmox, Node Exporter and cAdvisor service coverage;
- recorded VM 300 as on demand and VM 400 as the active agent VM;
- added `192.168.1.60` and the public Cloudflare DNS path to the network plan;
- reconciled the Cloudflare token mount, Access policy and DNS troubleshooting;
- expanded USB storage scope to VM and application backup sets;
- updated the service inventory to distinguish always-on and on-demand loads;
- converted the empty legacy `docs/services/docker.md` into a valid pointer;
- added lifecycle guidance for Home Assistant and monitoring maintenance.

## Documentation rule

A service is listed as deployed only after installation and validation.
Planned services must remain outside the production inventory. Credentials,
personal identifiers and private agent workspaces must never be copied into
tracked documentation.

## Follow-up triggers

Repeat the audit after:

- the planned physical memory upgrade;
- deploying a new VM or n8n;
- changing public Cloudflare hostnames;
- changing backup retention or schedules;
- enabling new Hermes tools or administrative integrations.
