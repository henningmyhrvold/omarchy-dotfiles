#!/bin/bash
set -e
# One-time Omarchy customizations — run once by bootstrap.sh

# Install extra themes
omarchy-theme-install https://github.com/abhijeet-swami/omarchy-ayaka-theme
sleep 3
omarchy-theme-install https://github.com/JaxonWright/omarchy-midnight-theme
sleep 3
omarchy-theme-install https://github.com/bjarneo/omarchy-pulsar-theme
sleep 3
omarchy-theme-install https://github.com/abhijeet-swami/omarchy-spectra-theme
sleep 3

# Theme hook for additional theme support
#curl -fsSL https://imbypass.github.io/omarchy-theme-hook/install.sh | bash
#sleep 2
curl -fsSL https://raw.githubusercontent.com/JacobusXIII/omarchy-wireguard-vpn-toggle/main/install.sh | bash
sleep 3


# ============================================================================
# Omarchy Customizations
# ============================================================================

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Running Omarchy Customizations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Customize Spectre theme (Hyprland blur, gaps, touchpad, Ghostty settings)
if [ -f "./omarchy-mods-spectra-theme.sh" ]; then
    echo "Customizing Spectre theme..."
    bash ./omarchy-mods-spectra-theme.sh
else
    echo "⚠ Warning: omarchy-mods-spectra-theme.sh not found, skipping"
fi

echo ""

# Change Waybar logo to Arch Linux
if [ -f "./omarchy-mods-waybar.sh" ]; then
    echo "Changing Waybar logo..."
    bash ./omarchy-mods-waybar.sh
else
    echo "⚠ Warning: omarchy-mods-waybar.sh not found, skipping"
fi

echo ""

# Clean up unwanted applications
if [ -f "./omarchy-mods-cleanup.sh" ]; then
    echo "Cleaning up unwanted software..."
    bash ./omarchy-mods-cleanup.sh
else
    echo "⚠ Warning: omarchy-mods-cleanup.sh not found, skipping"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Omarchy Customizations Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Please reload Hyprland to apply all changes:"
echo "  Press: Super+Shift+R"
echo ""
