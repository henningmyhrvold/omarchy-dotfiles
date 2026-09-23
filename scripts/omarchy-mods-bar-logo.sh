#!/usr/bin/env bash
set -euo pipefail

# Replace the Quickshell bar's Omarchy glyph with the Arch Nerd Font glyph.
#
# The glyph is hardcoded in the package-owned menu BarWidget, not in shell.json:
#   $OMARCHY_PATH/shell/plugins/menu/BarWidget.qml
#   text: "\ue900"        -> "omarchy" font private-use glyph
#   fontFamily: "omarchy" -> font that only contains e900..e908
#
# This is the least invasive change: two tokens in one file, nothing else
# touched, so the menu and its handlers are unaffected. Because the file is
# package-owned, `omarchy-update` reverts it — re-run this script afterwards.

FILE="${OMARCHY_PATH:-/usr/share/omarchy}/shell/plugins/menu/BarWidget.qml"

[[ -f "$FILE" ]] || { echo "Omarchy shell BarWidget.qml not found: $FILE" >&2; exit 1; }
[[ $(omarchy version) == 4.* ]] || { echo 'Omarchy 4 is required.' >&2; exit 1; }

if grep -q 'text: "\\uf303"' "$FILE"; then
    echo 'Arch logo already installed.'
    exit 0
fi

BACKUP="$FILE.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp "$FILE" "$BACKUP"
echo "Backup saved: $BACKUP"

sudo sed -i \
    -e 's|text: "\\ue900"|text: "\\uf303"|' \
    -e 's|fontFamily: "omarchy"|fontFamily: "JetBrainsMono Nerd Font"|' \
    "$FILE"

omarchy-restart-shell
echo 'Bar logo switched to the Arch glyph. Re-run this script after omarchy-update reverts it.'