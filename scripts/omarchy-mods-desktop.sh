#!/usr/bin/env bash
# Apply the user-level desktop from local checkouts. No package/service changes.
set -euo pipefail
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
DOTFILES_DIR=$(dirname "$SCRIPT_DIR")
THEME_DIR=${SPECTRA_THEME_DIR:-$(dirname "$DOTFILES_DIR")/omarchy-spectra-theme}
export OMARCHY_PATH=${OMARCHY_PATH:-/usr/share/omarchy}

[[ $(omarchy version) == 4.* ]] || { echo 'This setup requires Omarchy 4.' >&2; exit 1; }
[[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]] || { echo 'Run this in your Omarchy desktop session.' >&2; exit 1; }
[[ -f "$THEME_DIR/shell.toml" ]] || { echo "Migrated Spectra checkout missing: $THEME_DIR" >&2; exit 1; }

python "$SCRIPT_DIR/config-edit.py" link "$HOME/.config/omarchy/themes/spectra" "$THEME_DIR"
bash "$SCRIPT_DIR/omarchy-mods-hyprland-global.sh"
python "$SCRIPT_DIR/config-edit.py" block "$HOME/.config/hypr/looknfeel.lua" "$DOTFILES_DIR/hypr/looknfeel.lua" --marker omarchy-dotfiles-glass
hyprctl reload
errors=$(hyprctl configerrors)
[[ -z ${errors//[[:space:]]/} ]] || { echo "$errors" >&2; exit 1; }

# Keep the hook in the checkout so rerunning/pulling dotfiles updates it too.
python "$SCRIPT_DIR/config-edit.py" link "$HOME/.config/omarchy/hooks/theme-set.d/terminal-preferences" "$DOTFILES_DIR/omarchy-hooks/theme-set"
bash "$DOTFILES_DIR/omarchy-hooks/theme-set"
python "$SCRIPT_DIR/config-edit.py" copy "$HOME/.config/omarchy/branding/screensaver.txt" "$DOTFILES_DIR/logo/arch.txt"
omarchy theme set spectra
hyprctl reload
errors=$(hyprctl configerrors)
[[ -z ${errors//[[:space:]]/} ]] || { echo "$errors" >&2; exit 1; }
echo 'Spectra desktop applied. Native Quattro notifications and DND are enabled.'
