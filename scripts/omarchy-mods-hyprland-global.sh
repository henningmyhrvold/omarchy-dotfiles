#!/usr/bin/env bash
set -e

# Configure Omarchy Input Settings
# Modifies ~/.config/hypr/input.conf for keyboard and touchpad settings

INPUT_CONF="$HOME/.config/hypr/input.conf"

# Check if input.conf exists
if [ ! -f "$INPUT_CONF" ]; then
    echo "Error: Input config not found at $INPUT_CONF"
    echo "You can access it via: Super + Alt + Space → Setup → Input"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Omarchy Input Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This will configure:"
echo "  • Keyboard layout: us,no (US + Norwegian)"
echo "  • Layout switch: Alt+Shift"
echo "  • Touchpad natural scroll: yes (Mac-style)"
echo ""

# Create backup
BACKUP="$INPUT_CONF.backup-$(date +%Y%m%d-%H%M%S)"
cp "$INPUT_CONF" "$BACKUP"
echo "Backup created: $BACKUP"
echo ""

# Set keyboard layout to us,no
if grep -q "^\s*kb_layout" "$INPUT_CONF"; then
    # Update existing kb_layout
    sed -i 's/^\(\s*\)kb_layout.*/\1kb_layout = us,no/' "$INPUT_CONF"
    echo "✓ Updated: kb_layout = us,no"
else
    # Add kb_layout after input {
    sed -i '/^input {/a\    kb_layout = us,no' "$INPUT_CONF"
    echo "✓ Added: kb_layout = us,no"
fi

# Set keyboard options for Alt+Shift toggle
if grep -q "^\s*kb_options" "$INPUT_CONF"; then
    # Update existing kb_options
    sed -i 's/^\(\s*\)kb_options.*/\1kb_options = grp:alt_shift_toggle/' "$INPUT_CONF"
    echo "✓ Updated: kb_options = grp:alt_shift_toggle"
else
    # Add kb_options after kb_layout
    sed -i '/kb_layout = us,no/a\    kb_options = grp:alt_shift_toggle' "$INPUT_CONF"
    echo "✓ Added: kb_options = grp:alt_shift_toggle"
fi

# Set touchpad natural scroll
if grep -q "^\s*natural_scroll" "$INPUT_CONF"; then
    # Update existing natural_scroll
    sed -i 's/^\(\s*\)natural_scroll.*/\1natural_scroll = yes/' "$INPUT_CONF"
    echo "✓ Updated: natural_scroll = yes"
else
    # Add natural_scroll in touchpad section
    if grep -q "touchpad {" "$INPUT_CONF"; then
        sed -i '/touchpad {/a\        natural_scroll = yes' "$INPUT_CONF"
        echo "✓ Added: natural_scroll = yes (in touchpad section)"
    else
        # Create touchpad section if it doesn't exist
        sed -i '/^input {/a\    touchpad {\n        natural_scroll = yes\n    }' "$INPUT_CONF"
        echo "✓ Added: touchpad section with natural_scroll = yes"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Configuration Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "CHANGES MADE:"
echo "  • Keyboard layouts: us,no"
echo "  • Layout toggle: Alt+Shift"
echo "  • Touchpad scroll: natural (Mac-style)"
echo ""
echo "TO APPLY:"
echo "  • Reload Hyprland: Super+Shift+R"
echo ""
echo "TO REVERT:"
echo "  cp $BACKUP $INPUT_CONF"
echo ""
echo "Current input.conf content:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$INPUT_CONF"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
