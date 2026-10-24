#!/usr/bin/env bash
# ==============================================================================
# IPRegion backward-compatibility forwarding wrapper for VPNCheck
# ==============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/vpncheck.sh" "$@"
