#!/usr/bin/env bash
set -euo pipefail

VAULT_ROOT="${1:-/home/hermes/.hermes/obsidian}"

mkdir -p "$VAULT_ROOT"
mkdir -p "$VAULT_ROOT/attachments"
mkdir -p "$VAULT_ROOT/templates"

cat > "$VAULT_ROOT/00-inbox.md" <<'EOF'
# Hermes Inbox

Use this note for short, unreviewed facts that Hermes should remember later.

- Date:
- Source:
- Fact:
- Confidence:
- Action needed:
EOF

cat > "$VAULT_ROOT/10-profile.md" <<'EOF'
# Hermes Profile

## Stable facts

- Agent name: Hermes
- Host: agent01
- VMID: 400
- LAN IP: 192.168.1.60

## Approved context

- Add stable project facts here.
- Keep this note free of secrets.
EOF

cat > "$VAULT_ROOT/20-projects.md" <<'EOF'
# Hermes Projects

## Active work

- QuesadaLab homelab operations
- Messaging integrations
- Scheduled workflows
- Documentation maintenance
EOF

cat > "$VAULT_ROOT/30-operations.md" <<'EOF'
# Hermes Operations

## Current operational reminders

- Do not print secrets.
- Verify the live provider before changing models.
- Back up before changing gateway or credentials.
- Keep Hermes off public exposure paths.
EOF

cat > "$VAULT_ROOT/90-archive.md" <<'EOF'
# Hermes Archive

Use this note for old context that is no longer active.
EOF

echo "Hermes Obsidian vault initialized at: $VAULT_ROOT"
echo "Suggested personal vault: /opt/quesadalab/data/obsidian/personal"
