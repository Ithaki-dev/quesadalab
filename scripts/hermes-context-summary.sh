#!/usr/bin/env bash
set -euo pipefail

echo "Hermes context summary for QuesadaLab"
echo
echo "Core locations:"
echo "  repo: /opt/quesadalab-repo"
echo "  vm: agent01 (VMID 400)"
echo "  data root: /home/hermes/.hermes"
echo "  gateway: hermes-gateway.service"
echo
echo "Key docs:"
echo "  docs/services/hermes-agent/AGENT-BRIEF.md"
echo "  docs/services/hermes-agent/README.md"
echo "  docs/runbooks/hermes-operations.md"
echo "  docs/runbooks/hermes-backup.md"
echo "  docs/runbooks/hermes-restore.md"
echo
echo "Safe checks:"
echo "  hermes doctor"
echo "  hermes gateway status"
echo "  systemctl --user status hermes-gateway.service --no-pager"
echo "  journalctl --user -u hermes-gateway.service -n 100 --no-pager"
echo
echo "Rules:"
echo "  - Do not print secrets"
echo "  - Do not expose Hermes publicly"
echo "  - Do not modify .env without backup"
echo "  - Verify live provider config before changes"
