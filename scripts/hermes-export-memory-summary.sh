#!/usr/bin/env bash
set -euo pipefail

HERMES_VAULT_ROOT="${1:-/home/hermes/.hermes/obsidian}"
PERSONAL_VAULT_ROOT="${2:-/opt/quesadalab/data/obsidian/personal}"
EXPORT_DIR="$PERSONAL_VAULT_ROOT/Imported-from-Hermes"
STAMP="$(date +%Y-%m-%d)"
EXPORT_FILE="$EXPORT_DIR/hermes-summary-$STAMP.md"

mkdir -p "$EXPORT_DIR"

if [ ! -d "$HERMES_VAULT_ROOT" ]; then
  echo "[ERROR] Hermes vault not found: $HERMES_VAULT_ROOT" >&2
  exit 1
fi

cat > "$EXPORT_FILE" <<EOF
# Hermes summary - $STAMP

This file contains curated, non-secret context exported from Hermes memory.

## Current memory snapshot

- Agent: Hermes
- Host: agent01
- Vault source: $HERMES_VAULT_ROOT
- Exported to: $PERSONAL_VAULT_ROOT

## Approved reminders

- Keep Hermes memory local.
- Export only curated summaries into the personal vault.
- Do not export secrets, tokens, recovery codes, or raw logs.

## Active context

- QuesadaLab homelab operations
- Messaging gateway maintenance
- Documentation and recovery runbooks
- Obsidian vault separation between personal and Hermes memory

## Next review

- Review this summary before promoting new facts into the personal vault.
EOF

echo "Hermes memory summary exported to: $EXPORT_FILE"
