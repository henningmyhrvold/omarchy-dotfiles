#!/usr/bin/env bash
# Interactive post-install entry point; works from any working directory.
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
if [[ ${1:-} == --desktop-only ]]; then
    shift
    exec bash "$SCRIPT_DIR/omarchy-mods-desktop.sh" "$@"
fi
if (( $# )); then
    echo 'Usage: omarchy-mods-first-time.sh [--desktop-only]' >&2
    exit 1
fi
trap 'echo "Setup stopped at line $LINENO. Fix the error above and rerun; completed desktop edits are idempotent." >&2' ERR

[[ $(omarchy version) == 4.* ]] || { echo 'Omarchy 4 is required.' >&2; exit 1; }
THEME_DIR=${SPECTRA_THEME_DIR:-$(dirname "$(dirname "$SCRIPT_DIR")")/omarchy-spectra-theme}
if [[ ! -d "$THEME_DIR" ]]; then
    git clone https://github.com/henningmyhrvold/omarchy-spectra-theme.git "$THEME_DIR"
fi
export SPECTRA_THEME_DIR="$THEME_DIR"

sudo systemctl enable --now sshd
bash "$SCRIPT_DIR/omarchy-mods-desktop.sh"
bash "$SCRIPT_DIR/omarchy-mods-cleanup.sh"
bash "$SCRIPT_DIR/omarchy-mods-branding.sh"
bash "$SCRIPT_DIR/omarchy-mods-hyprland-global.sh"
echo 'Setup complete.'
