#!/usr/bin/env bash
set -e

# Customize Omarchy Spectre Theme
# Modifies Hyprland blur settings in the Spectre theme

THEME_DIR="$HOME/.config/omarchy/themes/spectra/"
HYPRLAND_CONF="$THEME_DIR/hyprland.conf"

# Check if the theme directory exists
if [ ! -d "$THEME_DIR" ]; then
    echo "Error: Omarchy Spectre theme directory not found at $THEME_DIR"
    exit 1
fi

# Check if hyprland.conf exists
if [ ! -f "$HYPRLAND_CONF" ]; then
    echo "Error: Hyprland config not found at $HYPRLAND_CONF"
    exit 1
fi

echo "Customizing Omarchy Spectre theme Hyprland config..."

# Create backup
BACKUP="$HYPRLAND_CONF.backup-$(date +%Y%m%d-%H%M%S)"
cp "$HYPRLAND_CONF" "$BACKUP"
echo "Backup created: $BACKUP"

# Use sed to modify the blur settings
# This preserves the file structure and only changes specific values
sed -i \
    -e 's/^\(\s*\)size = 4$/\1size = 6/' \
    -e 's/^\(\s*\)contrast = 1\.0$/\1contrast = 1.5/' \
    -e 's/^\(\s*\)vibrancy = 0\.1$/\1vibrancy = 0.5/' \
    -e 's/^\(\s*\)noise = 0\.01$/\1noise = 0.04/' \
    -e 's/^\(\s*\)ignore_opacity = false$/\1ignore_opacity = true/' \
    -e 's/^\(\s*\)inactive_opacity = 0\.95$/\1inactive_opacity = 0.9/' \
    "$HYPRLAND_CONF"

# Add vibrancy_darkness if it doesn't exist (insert after vibrancy line)
if ! grep -q "vibrancy_darkness" "$HYPRLAND_CONF"; then
    sed -i '/^\s*vibrancy = 0\.5$/a\        vibrancy_darkness = 0.4' "$HYPRLAND_CONF"
    echo "Added vibrancy_darkness = 0.4"
fi

echo "✓ Hyprland config updated successfully"
echo ""
echo "Changes made:"
echo "  • blur.size: 4 → 6"
echo "  • blur.contrast: 1.0 → 1.5"
echo "  • blur.vibrancy: 0.1 → 0.5"
echo "  • blur.vibrancy_darkness: added (0.4)"
echo "  • blur.noise: 0.01 → 0.04"
echo "  • blur.ignore_opacity: false → true"
echo "  • inactive_opacity: 0.95 → 0.9"
echo ""
echo "To apply changes, reload Hyprland (Super+Shift+R or restart)"
echo "To revert, restore from backup: cp $BACKUP $HYPRLAND_CONF"
