#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
CONFIG="$HOME/.config/omarchy/shell.json"
PLUGIN_ID="${USER:-$(id -un)}.menu"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || { echo 'Run shell setup inside your Omarchy desktop session.' >&2; exit 1; }
if [[ ! -e "$PLUGIN_DIR" ]]; then
    python "$SCRIPT_DIR/config-edit.py" backup "$CONFIG"
    omarchy plugin clone omarchy.menu
fi
jq -e '.omarchy.clonedFrom == "omarchy.menu"' "$PLUGIN_DIR/manifest.json" >/dev/null
python "$SCRIPT_DIR/config-edit.py" copy "$PLUGIN_DIR/BarWidget.qml" "$SCRIPT_DIR/../shell/BarWidget.qml"
python "$SCRIPT_DIR/config-edit.py" shell "$CONFIG"
omarchy plugin enable "$PLUGIN_ID"
echo 'Arch menu icon installed; the shell reloads it automatically.'
