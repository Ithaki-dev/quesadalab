# ADR-006

## Title

Vaultwarden as the internal password manager.

## Status

Accepted

## Context

QuesadaLab requires a private password manager compatible with Bitwarden clients.
This sensitive service needs internal HTTPS, restricted registration, controlled
deployments, consistent backups and a defined recovery procedure.

## Decision

Use Vaultwarden on `docker01` with:

- persistent data under `/opt/quesadalab/data/vaultwarden`;
- configuration and secrets outside Git;
- Traefik TLS termination at `https://vault.lab`;
- access restricted to the internal network;
- public registration disabled and a protected administrative token;
- daily backups with checksum, manifest and seven-set retention;
- systemd scheduling and controlled deployments without implicit pulls;
- HTTPS availability monitoring through `/alive`.

Application-data backups and deployment-configuration backups remain separate.
Restores require explicit approval and are not automatically triggered.

## Consequences

### Advantages

- Compatible with existing Bitwarden clients.
- Control over data location and backup policy.
- Valid internal HTTPS without bypassing certificate verification.
- Reproducible configuration and operational runbooks.

### Trade-offs and risks

- QuesadaLab owns updates, monitoring and recovery.
- The `latest` tag requires disciplined optional pulls.
- Backups contain sensitive data and need restricted access.
- Restore can replace active data and must be tested in isolation.
- Availability depends on Docker, Traefik, DNS and the internal PKI.
