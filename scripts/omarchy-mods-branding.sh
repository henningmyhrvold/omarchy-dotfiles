#!/usr/bin/env bash
set -e

# Replace Omarchy branding with custom ARCH logo
#
# Covers:
#
# 1. SCREENSAVER + TERMINAL PRESENTATION BRANDING (ASCII text)
#    Location: ~/.config/omarchy/branding/screensaver.txt
#    Used by the screensaver (tte effects) and floating terminal presentations.
#
# 2. PLYMOUTH BOOT/SHUTDOWN SCREEN
#    Location: /usr/share/plymouth/themes/omarchy/logo.png
#    Graphical PNG shown during LUKS password entry and shutdown/reboot.
#    Requires sudo + initramfs rebuild.
#
# Source files expected at:
#   ~/src/omarchy-dotfiles/logo/arch.txt  (ASCII art for screensaver)
#   ~/src/omarchy-dotfiles/logo/arch.png  (PNG image for Plymouth boot/shutdown)

DOTFILES_DIR="$HOME/src/omarchy-dotfiles/logo"
ASCII_SOURCE="$DOTFILES_DIR/arch.txt"
PNG_SOURCE="$DOTFILES_DIR/arch.png"

PLYMOUTH_THEME_DIR="/usr/share/plymouth/themes/omarchy"
BRANDING_DIR="$HOME/.config/omarchy/branding"

echo "┌──────────────────────────────────────────────────┐"
echo "  Omarchy Branding Replacement (ARCH)"
echo "└──────────────────────────────────────────────────┘"
echo ""

# ============================================================================
# 1. Screensaver / terminal presentation branding (ASCII text)
# ============================================================================
echo "==> [1/2] Screensaver / terminal branding (ASCII art)"
echo ""

if [ ! -f "$ASCII_SOURCE" ]; then
    echo "  ⚠  ASCII source not found: $ASCII_SOURCE"
    echo "  Skipping screensaver branding replacement."
else
    mkdir -p "$BRANDING_DIR"

    DEST="$BRANDING_DIR/screensaver.txt"
    if [ -f "$DEST" ]; then
        BACKUP="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
        cp "$DEST" "$BACKUP"
        echo "  Backup saved: $BACKUP"
    fi

    cp "$ASCII_SOURCE" "$DEST"
    echo "  ✔ Screensaver branding updated: $DEST"
fi

echo ""

# ============================================================================
# 2. Plymouth boot/shutdown logo (PNG — requires sudo)
# ============================================================================
echo "==> [2/2] Plymouth boot/shutdown logo (disk encryption + shutdown)"
echo ""

if [ ! -f "$PNG_SOURCE" ]; then
    echo "  ⚠  PNG source not found: $PNG_SOURCE"
    echo ""
    echo "  To create one from your ASCII art, you can use ImageMagick:"
    echo "    convert -size 800x400 xc:black -font 'Hack-Regular' \\"
    echo "      -pointsize 16 -fill white -gravity center \\"
    echo "      -annotate 0 \"\$(cat $ASCII_SOURCE)\" $PNG_SOURCE"
    echo ""
    echo "  Or create a custom arch.png (recommended: ~400-800px wide,"
    echo "  transparent or black background, white text/logo)."
    echo ""
    echo "  Skipping Plymouth logo replacement."
elif [ ! -d "$PLYMOUTH_THEME_DIR" ]; then
    echo "  ⚠  Plymouth theme directory not found: $PLYMOUTH_THEME_DIR"
    echo "  Skipping Plymouth logo replacement."
else
    if [ -f "$PLYMOUTH_THEME_DIR/logo.png" ]; then
        BACKUP="$PLYMOUTH_THEME_DIR/logo.png.backup-$(date +%Y%m%d-%H%M%S)"
        sudo cp "$PLYMOUTH_THEME_DIR/logo.png" "$BACKUP"
        echo "  Backup saved: $BACKUP"
    fi

    sudo cp "$PNG_SOURCE" "$PLYMOUTH_THEME_DIR/logo.png"
    echo "  ✔ Plymouth logo replaced"
    echo ""
    echo "  Rebuilding initramfs to include the new logo..."
    sudo mkinitcpio -P
    echo "  ✔ Initramfs rebuilt"
fi

echo ""
echo "┌──────────────────────────────────────────────────┐"
echo "  Branding Replacement Complete!"
echo "└──────────────────────────────────────────────────┘"
echo ""
echo "SUMMARY:"
echo "  • Screensaver (ASCII):      $BRANDING_DIR/screensaver.txt"
echo "  • Plymouth (boot/shutdown): $PLYMOUTH_THEME_DIR/logo.png"
echo ""
echo "NOTE: Plymouth changes require sudo and survive omarchy-update,"
echo "but may be overwritten by major Omarchy upgrades. Re-run after"
echo "major updates if the logo reverts."
echo ""
echo "TO TEST:"
echo "  Screensaver: Omarchy Menu > Trigger > Toggle > Screensaver"
echo "  Plymouth:    Reboot your machine"
