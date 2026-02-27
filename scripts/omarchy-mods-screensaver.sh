#!/usr/bin/env bash
set -e

# Replace Omarchy screensaver logo with custom ARCH ASCII art
# Source: ~/src/omarchy-dotfiles/logo/screensaver.txt
# Destination: ~/.config/omarchy/branding/screensaver.txt

SOURCE="$HOME/src/omarchy-dotfiles/logo/screensaver.txt"
DEST_DIR="$HOME/.config/omarchy/branding"
DEST="$DEST_DIR/screensaver.txt"

# Check source file exists
if [ ! -f "$SOURCE" ]; then
    echo "Error: Source file not found at $SOURCE"
    exit 1
fi

# Ensure destination directory exists
mkdir -p "$DEST_DIR"

# Backup existing screensaver if present
if [ -f "$DEST" ]; then
    BACKUP="$DEST.backup-$(date +%Y%m%d-%H%M%S)"
    cp "$DEST" "$BACKUP"
    echo "Backup saved: $BACKUP"
fi

# Copy the custom logo
cp "$SOURCE" "$DEST"
echo "✔ Screensaver logo updated: $DEST"
echo ""
echo "The new screensaver will appear next time it triggers."
echo "Test it with: Omarchy Menu > Trigger > Toggle > Screensaver"
