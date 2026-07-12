# ADR-005

## Title

Traefik as reverse proxy.

## Status

Accepted

## Context

Multiple web services will be deployed inside Docker.

Accessing each service through ports is difficult to maintain.

## Decision

Use Traefik v3 as reverse proxy.

Hostnames

- traefik.lab
- portainer.lab
- whoami.lab

Docker Provider enabled.

Automatic discovery using labels.

Dedicated Docker network:

proxy

## Consequences

Advantages

- Automatic service discovery
- Cleaner URLs
- Easy HTTPS migration
- Cloudflare integration