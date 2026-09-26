#!/usr/bin/env bash
# Restore high-quality rendering on the native lock screen.
#
# The package-owned LockView.qml decodes the wallpaper through
# `sourceSize` without `smooth`/`mipmap`, so a huge background (6016x3388)
# is downsampled with a fast filter and the blur reads as aliased and
# low-resolution. Add the missing sampling flags to the lock wallpaper.
#
# The file lives in /usr/share/omarchy, so `omarchy update` reverts it —
# re-run this script afterwards.
set -euo pipefail

FILE="${OMARCHY_PATH:-/usr/share/omarchy}/shell/plugins/lock/LockView.qml"

[[ -f "$FILE" ]] || { echo "Omarchy shell LockView.qml not found: $FILE" >&2; exit 1; }
[[ $(omarchy version) == 4.* ]] || { echo 'Omarchy 4 is required.' >&2; exit 1; }

if grep -q 'mipmap: true' "$FILE"; then
    echo 'Lock screen sampling flags already installed.'
    exit 0
fi

BACKUP="$FILE.backup-$(date +%Y%m%d-%H%M%S)"
sudo cp "$FILE" "$BACKUP"
echo "Backup saved: $BACKUP"

# The wallpaper Image fills the lock surface; add smooth/mipmap right after
# `cache: false` inside its block. That token is unique to this file's Image.
sudo sed -i '0,/cache: false/{s/cache: false/cache: false\n      smooth: true\n      mipmap: true/}' \
    "$FILE"

omarchy-restart-shell
echo 'Lock screen sampling flags applied. Re-run this script after omarchy-update reverts it.'