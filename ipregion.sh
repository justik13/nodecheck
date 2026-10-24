#!/usr/bin/env bash
# ==============================================================================
# IPRegion backward-compatibility forwarding wrapper for VPNCheck
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

if [[ -f "${SCRIPT_DIR}/vpncheck.sh" ]]; then
  exec "${SCRIPT_DIR}/vpncheck.sh" "$@"
else
  exec bash <(curl -fsSL https://raw.githubusercontent.com/justik13/vpncheck/main/vpncheck.sh) "$@"
fi
