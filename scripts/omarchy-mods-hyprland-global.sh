#!/usr/bin/env bash
set -e

# Configure Omarchy Input Settings
# Modifies ~/.config/hypr/input.conf (old) or ~/.config/hypr/input.lua (new alpha)
# Auto-detects which format is in use.

INPUT_CONF="$HOME/.config/hypr/input.conf"
INPUT_LUA="$HOME/.config/hypr/input.lua"

# Detect which config file is in use.
# Prefer input.lua if it exists, since the new alpha uses that.
if [ -f "$INPUT_LUA" ]; then
    INPUT_FILE="$INPUT_LUA"
    FORMAT="lua"
elif [ -f "$INPUT_CONF" ]; then
    INPUT_FILE="$INPUT_CONF"
    FORMAT="conf"
else
    echo "Error: No input config found."
    echo "  Looked for: $INPUT_LUA"
    echo "  Looked for: $INPUT_CONF"
    echo "You can access it via: Super + Alt + Space → Setup → Input"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Omarchy Input Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Detected config format: $FORMAT"
echo "Editing: $INPUT_FILE"
echo ""
echo "This will configure:"
echo "  • Keyboard layout: us,no (US + Norwegian)"
echo "  • Layout switch: Alt+Shift"
echo "  • Touchpad natural scroll: yes (Mac-style)"
echo ""

# Create backup
BACKUP="$INPUT_FILE.backup-$(date +%Y%m%d-%H%M%S)"
cp "$INPUT_FILE" "$BACKUP"
echo "Backup created: $BACKUP"
echo ""

# ─────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────

# Match a key line whether it's active or commented out.
# Old conf:  `# kb_layout = ...` or `kb_layout = ...`
# New lua:   `-- kb_layout = ...` or `kb_layout = ...`
key_present() {
    local key="$1"
    grep -Eq "^[[:space:]]*(#|--)?[[:space:]]*${key}[[:space:]]*=" "$INPUT_FILE"
}

# Is there an *active* (uncommented) instance of this key?
key_active() {
    local key="$1"
    grep -Eq "^[[:space:]]*${key}[[:space:]]*=" "$INPUT_FILE"
}

# Rewrite only the first matching line. Both commented and uncommented
# lines match, but we stop after the first hit so example/template lines
# further down stay untouched.
#
# Preference order:
#   1. If an active line exists, rewrite that one.
#   2. Otherwise, rewrite the first commented-out line (uncommenting it).
#
# args: <key> <replacement-line>
rewrite_first() {
    local key="$1"
    local replacement="$2"

    if key_active "$key"; then
        # Rewrite first active occurrence
        sed -i -E "0,/^([[:space:]]*)${key}[[:space:]]*=.*/s||\\1${replacement}|" "$INPUT_FILE"
    else
        # Rewrite first commented occurrence (works for both `#` and `--`)
        sed -i -E "0,/^([[:space:]]*)(#|--)[[:space:]]*${key}[[:space:]]*=.*/s||\\1${replacement}|" "$INPUT_FILE"
    fi
}

# ─────────────────────────────────────────────────────────────────
# CONF format (old)
# ─────────────────────────────────────────────────────────────────
update_conf() {
    # kb_layout
    if key_present "kb_layout"; then
        rewrite_first "kb_layout" "kb_layout = us,no"
        echo "✓ Set: kb_layout = us,no"
    else
        sed -i '/^input {/a\  kb_layout = us,no' "$INPUT_FILE"
        echo "✓ Added: kb_layout = us,no"
    fi

    # kb_options
    if key_present "kb_options"; then
        rewrite_first "kb_options" "kb_options = grp:alt_shift_toggle"
        echo "✓ Set: kb_options = grp:alt_shift_toggle"
    else
        sed -i '/kb_layout = us,no/a\  kb_options = grp:alt_shift_toggle' "$INPUT_FILE"
        echo "✓ Added: kb_options = grp:alt_shift_toggle"
    fi

    # natural_scroll inside touchpad { }
    if key_present "natural_scroll"; then
        rewrite_first "natural_scroll" "natural_scroll = yes"
        echo "✓ Set: natural_scroll = yes"
    else
        if grep -q "touchpad {" "$INPUT_FILE"; then
            sed -i '/touchpad {/a\    natural_scroll = yes' "$INPUT_FILE"
            echo "✓ Added: natural_scroll = yes (in touchpad section)"
        else
            sed -i '/^input {/a\  touchpad {\n    natural_scroll = yes\n  }' "$INPUT_FILE"
            echo "✓ Added: touchpad section with natural_scroll = yes"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────
# LUA format (new alpha)
#
# Values in Lua use quoted strings ("us,no") and booleans (true).
# Lines may be commented with `--`. We strip a leading `--` so
# values that ship commented-out (like kb_layout) become active.
# ─────────────────────────────────────────────────────────────────
update_lua() {
    # kb_layout — string, quoted, ends with comma
    if key_present "kb_layout"; then
        rewrite_first "kb_layout" 'kb_layout = "us,no",'
        echo "✓ Set: kb_layout = \"us,no\""
    else
        # Insert after the `input = {` line
        sed -i '/input[[:space:]]*=[[:space:]]*{/a\    kb_layout = "us,no",' "$INPUT_FILE"
        echo "✓ Added: kb_layout = \"us,no\""
    fi

    # kb_options — string, quoted, ends with comma
    if key_present "kb_options"; then
        rewrite_first "kb_options" 'kb_options = "grp:alt_shift_toggle",'
        echo "✓ Set: kb_options = \"grp:alt_shift_toggle\""
    else
        sed -i '/kb_layout = "us,no",/a\    kb_options = "grp:alt_shift_toggle",' "$INPUT_FILE"
        echo "✓ Added: kb_options = \"grp:alt_shift_toggle\""
    fi

    # natural_scroll — Lua boolean, ends with comma
    if key_present "natural_scroll"; then
        rewrite_first "natural_scroll" "natural_scroll = true,"
        echo "✓ Set: natural_scroll = true"
    else
        if grep -Eq "touchpad[[:space:]]*=[[:space:]]*\{" "$INPUT_FILE"; then
            sed -i -E '/touchpad[[:space:]]*=[[:space:]]*\{/a\      natural_scroll = true,' "$INPUT_FILE"
            echo "✓ Added: natural_scroll = true (in touchpad section)"
        else
            # No touchpad table — add one after `input = {`
            sed -i '/input[[:space:]]*=[[:space:]]*{/a\    touchpad = {\n      natural_scroll = true,\n    },' "$INPUT_FILE"
            echo "✓ Added: touchpad table with natural_scroll = true"
        fi
    fi
}

# ─────────────────────────────────────────────────────────────────
# Dispatch
# ─────────────────────────────────────────────────────────────────
case "$FORMAT" in
    conf) update_conf ;;
    lua)  update_lua  ;;
esac

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
echo "  cp $BACKUP $INPUT_FILE"
echo ""
echo "Current $(basename "$INPUT_FILE") content:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cat "$INPUT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
