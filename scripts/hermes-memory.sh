#!/usr/bin/env bash
set -euo pipefail

COMMAND="${1:-}"
shift || true

HERMES_VAULT_ROOT="${HERMES_VAULT_ROOT:-/home/hermes/.hermes/obsidian}"
HERMES_MEMORY_SECTION="${HERMES_MEMORY_SECTION:-}"
PERSONAL_VAULT_ROOT="${PERSONAL_VAULT_ROOT:-}"

if [ -n "$HERMES_MEMORY_SECTION" ]; then
  case "$HERMES_MEMORY_SECTION" in
    *[!A-Za-z0-9._-]*)
      echo "[ERROR] Invalid HERMES_MEMORY_SECTION: $HERMES_MEMORY_SECTION" >&2
      exit 1
      ;;
  esac

  HERMES_VAULT_ROOT="$HERMES_VAULT_ROOT/$HERMES_MEMORY_SECTION"
fi

INBOX_FILE="$HERMES_VAULT_ROOT/00-inbox.md"
PROFILE_FILE="$HERMES_VAULT_ROOT/10-profile.md"
PROJECTS_FILE="$HERMES_VAULT_ROOT/20-projects.md"
OPERATIONS_FILE="$HERMES_VAULT_ROOT/30-operations.md"

ensure_vault() {
  if [ ! -d "$HERMES_VAULT_ROOT" ]; then
    echo "[ERROR] Hermes vault not found: $HERMES_VAULT_ROOT" >&2
    exit 1
  fi
}

write_note_block() {
  local file="$1"
  local title="$2"
  local content="$3"
  {
    printf '\n## %s\n\n' "$title"
    printf '%s\n' "$content"
  } >> "$file"
}

case "$COMMAND" in
  init)
    bash "$(dirname "$0")/obsidian-setup.sh" "$HERMES_VAULT_ROOT"
    ;;
  remember)
    ensure_vault
    fact="${*:-}"
    if [ -z "$fact" ]; then
      echo "Usage: $0 remember <fact>" >&2
      exit 1
    fi
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    mkdir -p "$(dirname "$INBOX_FILE")"
    if [ ! -f "$INBOX_FILE" ]; then
      printf '# Hermes Inbox\n\n' > "$INBOX_FILE"
    fi
    write_note_block "$INBOX_FILE" "$timestamp" "- Fact: $fact"
    echo "Recorded fact in: $INBOX_FILE"
    ;;
  snapshot)
    ensure_vault
    for file in "$PROFILE_FILE" "$PROJECTS_FILE" "$OPERATIONS_FILE"; do
      if [ -f "$file" ]; then
        echo "--- $file ---"
        sed -n '1,120p' "$file"
      fi
    done
    ;;
  export-summary)
    bash "$(dirname "$0")/hermes-export-memory-summary.sh" "$HERMES_VAULT_ROOT" "$PERSONAL_VAULT_ROOT"
    ;;
  task-complete)
    ensure_vault
    summary="${*:-}"
    if [ -z "$summary" ]; then
      echo "Usage: $0 task-complete <summary>" >&2
      exit 1
    fi
    timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    mkdir -p "$HERMES_VAULT_ROOT"
    if [ ! -f "$OPERATIONS_FILE" ]; then
      printf '# Hermes Operations\n\n' > "$OPERATIONS_FILE"
    fi
    {
      printf '\n## %s\n\n' "$timestamp"
      printf '%s\n\n' "$summary"
      printf '%s\n' "- Exported to personal vault after task completion."
    } >> "$OPERATIONS_FILE"
    bash "$(dirname "$0")/hermes-export-memory-summary.sh" "$HERMES_VAULT_ROOT" "$PERSONAL_VAULT_ROOT"
    ;;
  *)
    cat <<'EOF'
Usage:
  hermes-memory.sh init
  hermes-memory.sh remember <fact>
  hermes-memory.sh snapshot
  hermes-memory.sh export-summary
  hermes-memory.sh task-complete <summary>

Optional:
  HERMES_MEMORY_SECTION=ithakidev hermes-memory.sh task-complete <summary>
EOF
    exit 1
    ;;
esac
