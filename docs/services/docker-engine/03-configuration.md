# Docker Configuration

## Directory Structure

```text
/opt/quesadalab

├── stacks
├── data
├── backups
├── scripts
└── docs
```

## Docker Network

A shared Docker network named `proxy` is used by Traefik and all published services.

## Storage Strategy

Every service stores persistent data under:

```
/opt/quesadalab/data/
```