#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="${1:-hermes/ithakidev}"
TARGET_HOST="${2:-hermes@192.168.1.60}"
TARGET_DIR="${3:-/home/hermes/.hermes/workspaces/ithakidev}"
SSH_KEY="${SSH_KEY:-/root/.ssh/quesadalab-agent01}"
SETUP_SCRIPT="scripts/obsidian-ithakidev-setup.sh"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "[ERROR] Source directory not found: $SOURCE_DIR" >&2
  exit 1
fi

if [ ! -f "$SETUP_SCRIPT" ]; then
  echo "[ERROR] Setup script not found: $SETUP_SCRIPT" >&2
  exit 1
fi

ssh -i "$SSH_KEY" "$TARGET_HOST" "mkdir -p '$TARGET_DIR'"

scp -i "$SSH_KEY" \
  "$SOURCE_DIR/README.md" \
  "$SOURCE_DIR/profile.md" \
  "$SOURCE_DIR/operating-prompt.md" \
  "$SOURCE_DIR/task-template.md" \
  "$TARGET_HOST:$TARGET_DIR/"

scp -i "$SSH_KEY" \
  "$SETUP_SCRIPT" \
  "$TARGET_HOST:/home/hermes/.hermes/obsidian-ithakidev-setup.sh"

ssh -i "$SSH_KEY" "$TARGET_HOST" "
  chmod 700 '$TARGET_DIR'
  chmod 600 '$TARGET_DIR/'*.md
  chmod 700 '/home/hermes/.hermes/obsidian-ithakidev-setup.sh'
  bash '/home/hermes/.hermes/obsidian-ithakidev-setup.sh' '/home/hermes/.hermes/obsidian'
  find '/home/hermes/.hermes/obsidian/ithakidev' -type d -exec chmod 700 {} \\;
  find '/home/hermes/.hermes/obsidian/ithakidev' -type f -exec chmod 600 {} \\;
"

echo "IthakiDev Hermes profile installed at: $TARGET_HOST:$TARGET_DIR"
echo "IthakiDev Hermes memory initialized at: $TARGET_HOST:/home/hermes/.hermes/obsidian/ithakidev"
