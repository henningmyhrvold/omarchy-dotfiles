#!/usr/bin/env bash
set -e

# Change Waybar Menu Logo from Omarchy to Arch Linux
# Replaces the Omarchy logo with the Arch Linux logo

WAYBAR_CONFIG="$HOME/.config/waybar/config.jsonc"

# Check if waybar config exists
if [ ! -f "$WAYBAR_CONFIG" ]; then
    echo "Error: Waybar config not found at $WAYBAR_CONFIG"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Waybar Logo Replacement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will replace the Omarchy logo with the Arch Linux logo"
echo "Using Nerd Font Arch icon (already installed in Omarchy)"
echo ""

# Show current configuration
echo "Current configuration:"
grep -A 4 '"custom/omarchy"' "$WAYBAR_CONFIG" || echo "  (custom/omarchy section not found)"
echo ""

read -p "Do you want to proceed? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Replacing logo with Nerd Font Arch icon..."

new_format=' '
logo_desc="Arch icon"

# Create a sed command to replace the format line
# Original: "format": "<span font='omarchy'></span>",
# New: "format": "",

sed -i.backup "/\"custom\/omarchy\":/,/},/ s|\"format\": \"<span font='omarchy'>.*</span>\"|\"format\": \"$new_format\"|" "$WAYBAR_CONFIG"

# Verify the change was made
if grep -q "\"format\": \"$new_format\"" "$WAYBAR_CONFIG"; then
    echo "✓ Logo replaced successfully!"
    echo ""
    echo "Changed to: $logo_desc"
    echo "Backup saved: ${WAYBAR_CONFIG}.backup"
else
    echo "⚠ Warning: Logo replacement might have failed"
    echo "Please check the config manually"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To apply changes:"
echo "  pkill waybar && waybar &"
echo ""
echo "Or reload Hyprland:"
echo "  Super+Shift+R"
echo ""
echo "To revert:"
echo "  mv ${WAYBAR_CONFIG}.backup $WAYBAR_CONFIG"
echo ""
