#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
INPUT="$HOME/.config/hypr/input.lua"

[[ -f "$INPUT" ]] || { echo "Omarchy 4 input.lua is required." >&2; exit 1; }
python "$SCRIPT_DIR/config-edit.py" block "$INPUT" "$SCRIPT_DIR/../hypr/input.lua" --marker omarchy-dotfiles-input

if [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload
    errors=$(hyprctl configerrors)
    [[ -z ${errors//[[:space:]]/} ]] || { echo "$errors" >&2; exit 1; }
fi
echo 'Configured US/Norwegian keyboard, Alt+Shift switching, and natural touchpad scrolling.'
