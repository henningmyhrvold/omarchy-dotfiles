#!/usr/bin/env bash
set -e

# Omarchy Software Removal Script
# Removes pre-installed software you don't need, using omarchy's own commands.

PACKAGES=(
    1password-beta
    1password-cli
    hwloc
    kdenlive
    libreoffice-still
    localsend
    obs-studio
    pinta
    spotify
    typora
    wiremix
    xournalpp
)

WEBAPPS=(
    Basecamp
    Figma
    Fizzy
    "Google Contacts"
    "Google Messages"
    "Google Photos"
    HEY
    WhatsApp
    X
    Zoom
)

TUIS=(
    "Disk Usage"
)

# Hyprland binding descriptions to remove (the 3rd comma-separated field in a bindd line).
# Match the "Description" exactly as it appears in bindings.conf.
BINDING_DESCRIPTIONS=(
    "Music"
    "Typora"
    "Passwords"
    "Email"
    "Grok"
    "Calendar"
    "WhatsApp"
    "Google Messages"
    "Google Photos"
    "X"
    "X Post"
)

BINDINGS_FILE="$HOME/.config/hypr/bindings.conf"

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
echo "Bindings to remove:  ${BINDING_DESCRIPTIONS[*]}"
echo ""
echo "Terminal will be switched to Ghostty."
echo ""

read -p "Proceed? (y/N) " -n 1 -r
echo ""
[[ ! $REPLY =~ ^[Yy]$ ]] && { echo "Aborted."; exit 0; }

echo ""
echo "━━━ Switching Terminal to ghostty ━━━"
omarchy install terminal ghostty
omarchy default terminal ghostty

echo ""
echo "━━━ Removing Webapps ━━━"
omarchy webapp remove "${WEBAPPS[@]}"

echo ""
echo "━━━ Removing TUIs ━━━"
omarchy tui remove "${TUIS[@]}"

echo ""
echo "━━━ Removing Packages ━━━"
sudo pacman -Rns --noconfirm "${PACKAGES[@]}"

echo ""
echo "━━━ Cleaning Cache ━━━"
sudo pacman -Sc --noconfirm
yay -Sc --noconfirm

echo ""
echo "━━━ Cleaning Hyprland Bindings ━━━"
if [[ -f "$BINDINGS_FILE" ]]; then
    cp "$BINDINGS_FILE" "$BINDINGS_FILE.bak"
    echo "  Backup: $BINDINGS_FILE.bak"

    for desc in "${BINDING_DESCRIPTIONS[@]}"; do
        # Escape regex metacharacters in the description, then match a bindd line
        # whose 3rd comma-separated field equals that description.
        esc=$(printf '%s' "$desc" | sed 's/[][\/.^$*]/\\&/g')
        if sed -i "/^bindd[[:space:]]*=[^,]*,[^,]*,[[:space:]]*${esc}[[:space:]]*,/d" "$BINDINGS_FILE"; then
            echo "  ✓ Removed binding: $desc"
        fi
    done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cleanup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Reload Hyprland to apply changes:"
echo "  Super+Shift+R"
echo ""
