#!/usr/bin/env bash
# Compatibility entry point for older instructions. Quattro uses omarchy-shell.
set -euo pipefail
exec bash "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/omarchy-mods-shell.sh" "$@"
