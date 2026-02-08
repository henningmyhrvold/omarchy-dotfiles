#!/usr/bin/env bash
set -e

# Change Waybar Menu Logo from Omarchy to Arch Linux

WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"

if [ ! -f "$WAYBAR_CONFIG" ]; then
    echo "Error: Waybar config not found at $WAYBAR_CONFIG"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Waybar Logo Replacement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "Current configuration:"
grep -A 4 '"custom/omarchy"' "$WAYBAR_CONFIG"
echo ""

read -p "Replace Omarchy logo with Arch Linux logo? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Create backup
cp "$WAYBAR_CONFIG" "${WAYBAR_CONFIG}.backup"
echo "✓ Backup created: ${WAYBAR_CONFIG}.backup"
echo ""

# Replace the icon
# Current: "format": "",
# Target:  "format": " ",

sed -i '/"custom\/omarchy":/,/}/ s|"format": ""|"format": " "|' "$WAYBAR_CONFIG"

echo "✓ Logo replaced!"
echo ""
echo "New configuration:"
grep -A 4 '"custom/omarchy"' "$WAYBAR_CONFIG"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To apply changes, reload Waybar:"
echo "  pkill waybar && waybar &"
echo ""
echo "Or press: Super+Shift+R"
echo ""
