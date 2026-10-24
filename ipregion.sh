#!/usr/bin/env bash
# ==============================================================================
# IPRegion backward-compatibility forwarding wrapper for NodeCheck
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

if [[ -f "${SCRIPT_DIR}/nodecheck.sh" ]]; then
  exec "${SCRIPT_DIR}/nodecheck.sh" "$@"
else
  exec bash <(curl -fsSL https://raw.githubusercontent.com/justik13/nodecheck/main/nodecheck.sh) "$@"
fi
