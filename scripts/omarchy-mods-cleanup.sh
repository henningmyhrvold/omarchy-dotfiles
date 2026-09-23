#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")

# Omarchy Software Removal Script
# Removes pre-installed software you don't need, using omarchy's own commands.

PACKAGES=(
    kdenlive
    obs-studio
    xournalpp
)

WEBAPPS=(
    Basecamp
    "Google Contacts"
    "Google Messages"
    "Google Photos"
    HEY
    WhatsApp
    X
    Zoom
    YouTube
)

TUIS=(
    "Disk Usage"
)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Omarchy Software Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Packages to remove:  ${PACKAGES[*]}"
echo ""
echo "Webapps to remove:   ${WEBAPPS[*]}"
echo ""
echo "TUIs to remove:      ${TUIS[*]}"
echo ""
echo "Terminal will be switched to Ghostty."
echo ""

read -p "Proceed? (y/N) " -n 1 -r
echo ""
[[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Aborted."; exit 0; }

echo ""
echo "━━━ Switching Terminal to ghostty ━━━"
omarchy install terminal ghostty
command -v ghostty >/dev/null
omarchy default terminal ghostty
bash "$SCRIPT_DIR/../omarchy-hooks/theme-set"

echo ""
echo "━━━ Removing Webapps ━━━"
for app in "${WEBAPPS[@]}"; do
    OMARCHY_REMOVE_NOTIFY=false omarchy webapp remove "$app"
done

echo ""
echo "━━━ Removing TUIs ━━━"
for app in "${TUIS[@]}"; do
    OMARCHY_REMOVE_NOTIFY=false omarchy tui remove "$app"
done

echo ""
echo "━━━ Removing Packages ━━━"
# Only pass packages that are actually installed. pacman -Rns exits non-zero on
# an unknown target, and `set -e` would abort the rest of the script.
to_remove=()
for pkg in "${PACKAGES[@]}"; do
    if pacman -Qq "$pkg" &>/dev/null; then
        to_remove+=("$pkg")
    else
        echo "  • skipping $pkg (not installed)"
    fi
done

if (( ${#to_remove[@]} > 0 )); then
    sudo pacman -Rns --noconfirm "${to_remove[@]}"
else
    echo "  Nothing to remove."
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cleanup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
