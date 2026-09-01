#!/usr/bin/env bash
set -euo pipefail

VAULT_ROOT="${1:-/home/hermes/.hermes/obsidian}"
SECTION_ROOT="$VAULT_ROOT/ithakidev"

mkdir -p "$SECTION_ROOT"
mkdir -p "$SECTION_ROOT/attachments"
mkdir -p "$SECTION_ROOT/templates"

cat > "$SECTION_ROOT/00-inbox.md" <<'EOF'
# IthakiDev Inbox

Use this note for unreviewed IthakiDev business facts, ideas, and task notes.

- Date:
- Source:
- Fact or idea:
- Confidence:
- Action needed:
EOF

cat > "$SECTION_ROOT/10-profile.md" <<'EOF'
# IthakiDev Profile

## Stable facts

- Business name: IthakiDev
- Primary domain: ithakidev.com
- Owner/operator: Robert Quesada
- Base location: Costa Rica

## Approved context

- Add stable business facts here.
- Keep this note free of secrets and private client data.
EOF

cat > "$SECTION_ROOT/20-projects.md" <<'EOF'
# IthakiDev Projects

## Active work

- Business profile setup
- Service packaging
- Website and automation planning
EOF

cat > "$SECTION_ROOT/30-operations.md" <<'EOF'
# IthakiDev Operations

## Operating reminders

- Keep client data private.
- Do not store credentials.
- Do not publish or contact clients without explicit approval.
- Back up before production changes.
EOF

cat > "$SECTION_ROOT/90-archive.md" <<'EOF'
# IthakiDev Archive

Use this note for old or inactive IthakiDev context.
EOF

echo "IthakiDev Obsidian memory section initialized at: $SECTION_ROOT"
