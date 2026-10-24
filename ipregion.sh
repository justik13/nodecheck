#!/usr/bin/env bash
# Backward compatibility wrapper for vpncheck.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/vpncheck.sh" "$@"
