#!/usr/bin/env bash
set -e

# Customize Omarchy Spectre Theme
# Modifies Hyprland blur settings in the Spectre theme

THEME_DIR="$HOME/.config/omarchy/themes/spectre"
HYPRLAND_CONF="$THEME_DIR/hyprland.conf"
GHOSTTY_CONF="$THEME_DIR/ghostty.conf"

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

# Check if ghostty.conf exists
if [ ! -f "$GHOSTTY_CONF" ]; then
    echo "Error: Ghostty config not found at $GHOSTTY_CONF"
    exit 1
fi

echo "Customizing Omarchy Spectre theme configs..."

# Create backups
HYPRLAND_BACKUP="$HYPRLAND_CONF.backup-$(date +%Y%m%d-%H%M%S)"
GHOSTTY_BACKUP="$GHOSTTY_CONF.backup-$(date +%Y%m%d-%H%M%S)"

cp "$HYPRLAND_CONF" "$HYPRLAND_BACKUP"
echo "Hyprland backup created: $HYPRLAND_BACKUP"

cp "$GHOSTTY_CONF" "$GHOSTTY_BACKUP"
echo "Ghostty backup created: $GHOSTTY_BACKUP"

echo ""
echo "==> Modifying Hyprland config..."

# Use sed to modify the blur settings
# This preserves the file structure and only changes specific values
sed -i \
    -e 's/^\(\s*\)size = 4$/\1size = 6/' \
    -e 's/^\(\s*\)contrast = 1\.0$/\1contrast = 1.5/' \
    -e 's/^\(\s*\)vibrancy = 0\.1$/\1vibrancy = 0.5/' \
    -e 's/^\(\s*\)noise = 0\.01$/\1noise = 0.04/' \
    -e 's/^\(\s*\)ignore_opacity = false$/\1ignore_opacity = true/' \
    -e 's/^\(\s*\)inactive_opacity = 0\.95$/\1inactive_opacity = 0.9/' \
    -e 's/^\(\s*\)gaps_in = 4$/\1gaps_in = 2/' \
    -e 's/^\(\s*\)gaps_out = 8$/\1gaps_out = 4/' \
    "$HYPRLAND_CONF"

# Add vibrancy_darkness if it doesn't exist (insert after vibrancy line)
if ! grep -q "vibrancy_darkness" "$HYPRLAND_CONF"; then
    sed -i '/^\s*vibrancy = 0\.5$/a\        vibrancy_darkness = 0.4' "$HYPRLAND_CONF"
    echo "  • Added vibrancy_darkness = 0.4"
fi

# Set touchpad natural scroll to true (Mac-style scrolling)
if grep -q "natural_scroll" "$HYPRLAND_CONF"; then
    # Update existing setting to true
    sed -i 's/^\(\s*\)natural_scroll.*$/\1natural_scroll = true/' "$HYPRLAND_CONF"
    echo "  • Set touchpad scroll: natural_scroll = true"
else
    # Add natural_scroll setting in the input section
    if grep -q "input {" "$HYPRLAND_CONF"; then
        sed -i '/input {/a\    touchpad {\n        natural_scroll = true\n    }' "$HYPRLAND_CONF"
        echo "  • Added touchpad natural_scroll = true"
    else
        echo "  ⚠ Could not find input section to add natural_scroll"
    fi
fi

echo "✓ Hyprland config updated"

echo ""
echo "==> Modifying Ghostty config..."

# Modify Ghostty settings
sed -i \
    -e 's/^background-opacity = 0\.6$/background-opacity = 0.95/' \
    -e 's/^font-size = 11$/font-size = 12/' \
    "$GHOSTTY_CONF"

# Add command = zsh if it doesn't exist (to launch zsh instead of bash)
if ! grep -q "^command = " "$GHOSTTY_CONF"; then
    # Add after the first line (usually a comment)
    sed -i '1a\
# Launch zsh instead of default shell\
command = zsh' "$GHOSTTY_CONF"
    echo "  • Added command = zsh (to launch zsh shell)"
elif ! grep -q "^command = zsh" "$GHOSTTY_CONF"; then
    # Replace existing command line
    sed -i 's/^command = .*/command = zsh/' "$GHOSTTY_CONF"
    echo "  • Changed shell command to: command = zsh"
fi

echo "✓ Ghostty config updated"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Omarchy Spectre Theme Customization Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "HYPRLAND CHANGES:"
echo "  • blur.size: 4 → 6"
echo "  • blur.contrast: 1.0 → 1.5"
echo "  • blur.vibrancy: 0.1 → 0.5"
echo "  • blur.vibrancy_darkness: added (0.4)"
echo "  • blur.noise: 0.01 → 0.04"
echo "  • blur.ignore_opacity: false → true"
echo "  • inactive_opacity: 0.95 → 0.9"
echo "  • gaps_in: 4 → 2"
echo "  • gaps_out: 8 → 4"
echo "  • touchpad natural_scroll: set to true (Mac-style)"
echo ""
echo "GHOSTTY CHANGES:"
echo "  • background-opacity: 0.6 → 0.95"
echo "  • font-size: 11 → 12"
echo "  • command: added/updated to 'zsh' (launches zsh shell)"
echo ""
echo "TO APPLY:"
echo "  • Hyprland: Press Super+Shift+R or restart"
echo "  • Ghostty: Restart the terminal"
echo ""
echo "TO REVERT:"
echo "  cp $HYPRLAND_BACKUP $HYPRLAND_CONF"
echo "  cp $GHOSTTY_BACKUP $GHOSTTY_CONF"
echo ""
