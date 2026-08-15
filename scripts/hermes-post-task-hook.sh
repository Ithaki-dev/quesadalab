#!/usr/bin/env bash
set -euo pipefail

SUMMARY="${1:-}"
shift || true

if [ -z "$SUMMARY" ]; then
  echo "Usage: $0 <summary>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -f "$SCRIPT_DIR/hermes-memory.sh" ]; then
  echo "[ERROR] Missing hermes-memory.sh next to this hook" >&2
  exit 1
fi

bash "$SCRIPT_DIR/hermes-memory.sh" task-complete "$SUMMARY" "$@"
