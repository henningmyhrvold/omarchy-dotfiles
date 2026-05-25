#!/bin/bash
set -e
# One-time Omarchy customizations
sudo systemctl enable --now sshd

# Install extra themes
omarchy-theme-install https://github.com/henningmyhrvold/omarchy-spectra-theme
sleep 3
omarchy-theme-install https://github.com/bjarneo/omarchy-pulsar-theme
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
#if [ -f "./omarchy-mods-spectra-theme.sh" ]; then
#    echo "Customizing Spectre theme..."
#    bash ./omarchy-mods-spectra-theme.sh
#else
#    echo "⚠ Warning: omarchy-mods-spectra-theme.sh not found, skipping"
#fi

echo ""

# Change Waybar logo to Arch Linux
if [ -f "./omarchy-mods-waybar.sh" ]; then
    echo "Changing Waybar logo..."
    bash ./omarchy-mods-waybar.sh
else
    echo "⚠ Warning: omarchy-mods-waybar.sh not found, skipping"
fi

echo ""

# Change input trackpad and language to Arch Linux
if [ -f "./omarchy-mods-hyprland-global.sh" ]; then
    echo "Changing input trackpad and language..."
    bash ./omarchy-mods-hyprland-global.sh
else
    echo "⚠ Warning: omarchy-mods-hyprland-global.sh not found, skipping"
fi

echo ""

# Clean up unwanted applications
if [ -f "./omarchy-mods-branding.sh" ]; then
    echo "Branding..."
    bash ./omarchy-mods-branding.sh
else
    echo "⚠ Warning: omarchy-mods-branding.sh not found, skipping"
fi

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
