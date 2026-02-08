#!/usr/bin/env bash
set -e

# Omarchy Software Removal Script
# Removes pre-installed software you don't need + cleans up keyboard shortcuts

BINDINGS_FILE="$HOME/.config/hypr/bindings.conf"

# Function to find keyboard bindings for an app/webapp
find_app_bindings() {
    local app_name="$1"
    local bindings=()

    if [[ ! -f "$BINDINGS_FILE" ]]; then
        return
    fi

    # Convert app name to lowercase for case-insensitive matching
    local app_lower=$(echo "$app_name" | tr '[:upper:]' '[:lower:]')

    # Define webapp URL patterns
    local webapp_domains=""
    case "$app_lower" in
        "hey") webapp_domains="app.hey.com|hey.com" ;;
        "basecamp") webapp_domains="basecamp.com|3.basecamp.com" ;;
        "whatsapp") webapp_domains="web.whatsapp.com|whatsapp.com" ;;
        "google photos"|"google-photos") webapp_domains="photos.google.com" ;;
        "google contacts"|"google-contacts") webapp_domains="contacts.google.com" ;;
        "google messages"|"google-messages"|"google messenger") webapp_domains="messages.google.com" ;;
        "figma") webapp_domains="figma.com" ;;
        "zoom") webapp_domains="zoom.us|zoom.com" ;;
    esac

    # Read bindings file and find matching lines
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue

        # Check if this is a bindd line
        if [[ "$line" =~ ^bindd[[:space:]]*= ]]; then
            local line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')

            # Check for app matches
            if [[ "$line_lower" =~ uwsm[[:space:]]+app[[:space:]]+--[[:space:]]+$app_lower([[:space:]]|$) ]]; then
                echo "$line"
            elif [[ "$line_lower" =~ \$terminal[[:space:]]+-e[[:space:]]+$app_lower([[:space:]]|$) ]]; then
                echo "$line"
            elif [[ "$line_lower" =~ omarchy-launch-webapp ]]; then
                if [[ -n "$webapp_domains" ]]; then
                    if [[ "$line" =~ omarchy-launch-webapp[[:space:]]+\"([^\"]+)\" ]]; then
                        local url="${BASH_REMATCH[1]}"
                        if [[ "$url" =~ ($webapp_domains) ]]; then
                            echo "$line"
                        fi
                    fi
                fi
            elif [[ "$app_lower" == "1password" ]] && [[ "$line_lower" =~ 1password ]]; then
                echo "$line"
            elif [[ "$app_lower" == "alacritty" ]] && [[ "$line_lower" =~ alacritty ]]; then
                echo "$line"
            elif [[ "$app_lower" == "spotify" ]] && [[ "$line_lower" =~ spotify ]]; then
                echo "$line"
            elif [[ "$app_lower" == "obsidian" ]] && [[ "$line_lower" =~ obsidian ]]; then
                echo "$line"
            fi
        fi
    done < "$BINDINGS_FILE" | sort -u
}

# Function to remove bindings from config file
remove_bindings_from_file() {
    local bindings_to_remove=("$@")

    if [[ ${#bindings_to_remove[@]} -eq 0 ]]; then
        return 0
    fi

    if [[ ! -f "$BINDINGS_FILE" ]]; then
        echo "  ⚠ Bindings file not found at $BINDINGS_FILE"
        return 1
    fi

    # Create temporary file
    local temp_file=$(mktemp)
    local removed_count=0

    # Process the file line by line
    while IFS= read -r line; do
        local should_remove=false

        # Check if this line should be removed
        for binding in "${bindings_to_remove[@]}"; do
            if [[ "$line" == "$binding" ]]; then
                should_remove=true
                ((removed_count++))
                break
            fi
        done

        # Write line to temp file if not removing
        if [[ "$should_remove" == false ]]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$BINDINGS_FILE"

    # Replace original file with temp file
    mv "$temp_file" "$BINDINGS_FILE"

    echo "  ✓ Removed $removed_count keyboard binding(s)"
    return 0
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Omarchy Software Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "This script will remove the following software:"
echo ""

# SOFTWARE ANALYSIS AND RECOMMENDATIONS
cat << 'EOF'
RECOMMENDED FOR REMOVAL:
========================

✗ 1Password (1password)
  Purpose: Password manager
  Why included: Popular enterprise password manager
  Recommendation: REMOVE - Only needed if you use 1Password service

✗ Alacritty (alacritty)
  Purpose: GPU-accelerated terminal emulator
  Why included: Fast, minimal terminal alternative
  Recommendation: REMOVE - You use Ghostty

✗ Basecamp (webapp)
  Purpose: Project management web app
  Why included: Made by 37signals (Omarchy creators)
  Recommendation: REMOVE - Only needed if you use Basecamp

✗ Figma (webapp)
  Purpose: Design tool web app
  Why included: Popular design tool
  Recommendation: REMOVE - Only needed for designers

✗ Fizzy (fizzy)
  Purpose: Chat/messaging client
  Why included: Modern messaging app
  Recommendation: REMOVE - Not widely used

✗ Google Contacts (webapp)
  Purpose: Contact management
  Why included: Google ecosystem integration
  Recommendation: REMOVE - Unless you rely on Google Contacts

✗ Google Messenger (webapp)
  Purpose: SMS/messaging via web
  Why included: Android integration
  Recommendation: REMOVE - Unless you use Google Messages

✗ Google Photos (webapp)
  Purpose: Photo storage/management
  Why included: Popular photo service
  Recommendation: REMOVE - Unless you use Google Photos

✗ Hey (webapp)
  Purpose: Email service from 37signals
  Why included: Made by 37signals
  Recommendation: REMOVE - Only if you use Hey email

✗ Kdenlive (kdenlive)
  Purpose: Video editing software
  Why included: Open-source video editor
  Recommendation: REMOVE - Only needed for video editing

✗ LibreOffice (grey icon - libreoffice-still)
  Purpose: Older stable version of LibreOffice
  Why included: Two versions shipped by mistake/choice
  Recommendation: REMOVE - Keep the regular version only

✗ Local Send (localsend)
  Purpose: Local file sharing app
  Why included: AirDrop alternative
  Recommendation: REMOVE - Only needed if you transfer files between devices

✗ OBS Studio (obs-studio)
  Purpose: Screen recording/streaming
  Why included: Popular streaming tool
  Recommendation: REMOVE - Only for content creators

✗ Obsidian (obsidian)
  Purpose: Note-taking with markdown
  Why included: Popular knowledge management tool
  Recommendation: REMOVE - Only if you use Obsidian

✗ Pinta (pinta)
  Purpose: Simple image editor (Paint.NET alternative)
  Why included: Quick image editing
  Recommendation: REMOVE - Basic image editing needs

✗ Spotify (spotify)
  Purpose: Music streaming
  Why included: Most popular music service
  Recommendation: REMOVE - You use YouTube Music

✗ Typora (typora)
  Purpose: Markdown editor
  Why included: Clean writing tool
  Recommendation: REMOVE - Unless you use it for writing

✗ WhatsApp (webapp)
  Purpose: Messaging service
  Why included: Most popular global messenger
  Recommendation: REMOVE - Only if you use WhatsApp

✗ Wiremix (wiremix)
  Purpose: Audio/music production
  Why included: Music creation tool
  Recommendation: REMOVE - Only for music producers

✗ Xournal++ (xournalpp)
  Purpose: Handwriting note-taking (PDF annotation)
  Why included: Note-taking with stylus
  Recommendation: REMOVE - Only needed with stylus/tablet

✗ Zoom (webapp)
  Purpose: Video conferencing
  Why included: Popular video calling
  Recommendation: REMOVE - Only if you use Zoom


KEEP (NOT REMOVED):
===================

✓ Aether - Unknown package, needs investigation
✓ Document Viewer (evince) - Useful for viewing PDFs
✓ Image Viewer (loupe/eog) - Essential for viewing images
✓ Media Player (mpv/vlc) - Essential for video playback
✓ Limine Snapper Restore - System recovery tool (KEEP!)

EOF

echo ""
read -p "Do you want to proceed with removal? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Starting removal process..."
echo ""

# Collect all bindings to remove
echo "━━━ Checking for Keyboard Shortcuts ━━━"
all_bindings_to_remove=()

# List of all apps and webapps we're removing
apps_to_check=(
    "1password" "alacritty" "fizzy" "kdenlive" "libreoffice-still"
    "localsend" "obs-studio" "obsidian" "pinta" "spotify"
    "typora" "wiremix" "xournalpp"
    "basecamp" "figma" "google-contacts" "google-messages"
    "google-photos" "hey" "whatsapp" "zoom"
)

for app in "${apps_to_check[@]}"; do
    bindings=$(find_app_bindings "$app")
    if [[ -n "$bindings" ]]; then
        echo "Found shortcuts for: $app"
        while IFS= read -r binding; do
            [[ -n "$binding" ]] && all_bindings_to_remove+=("$binding")
        done <<< "$bindings"
    fi
done

if [[ ${#all_bindings_to_remove[@]} -gt 0 ]]; then
    echo ""
    echo "Found ${#all_bindings_to_remove[@]} keyboard shortcut(s) to remove"
else
    echo "No keyboard shortcuts found for these apps"
fi

echo ""

# Function to remove package safely
remove_package() {
    local pkg="$1"
    local description="$2"

    if pacman -Q "$pkg" &>/dev/null; then
        echo "Removing: $description ($pkg)"
        sudo pacman -Rns --noconfirm "$pkg" || echo "  ⚠ Failed to remove $pkg (might have dependencies)"
    else
        echo "  ℹ $pkg not installed, skipping"
    fi
}

# Function to remove webapp
remove_webapp() {
    local webapp="$1"
    local description="$2"

    local webapp_file="$HOME/.local/share/applications/${webapp}.desktop"
    if [ -f "$webapp_file" ]; then
        echo "Removing webapp: $description"
        rm -f "$webapp_file"
        # Also remove from config if it exists
        rm -rf "$HOME/.config/${webapp}" 2>/dev/null || true
    else
        echo "  ℹ Webapp $webapp not found, skipping"
    fi
}

# Remove packages
echo "━━━ Removing Packages ━━━"
remove_package "1password" "1Password"
remove_package "alacritty" "Alacritty terminal"
remove_package "fizzy" "Fizzy messenger"
remove_package "kdenlive" "Kdenlive video editor"
remove_package "libreoffice-still" "LibreOffice (old version)"
remove_package "localsend" "LocalSend file sharing"
remove_package "obs-studio" "OBS Studio"
remove_package "obsidian" "Obsidian notes"
remove_package "pinta" "Pinta image editor"
remove_package "spotify" "Spotify"
remove_package "typora" "Typora markdown editor"
remove_package "wiremix" "Wiremix audio"
remove_package "xournalpp" "Xournal++"

echo ""
echo "━━━ Removing Web Apps ━━━"
remove_webapp "basecamp" "Basecamp"
remove_webapp "figma" "Figma"
remove_webapp "google-contacts" "Google Contacts"
remove_webapp "google-messages" "Google Messenger"
remove_webapp "google-photos" "Google Photos"
remove_webapp "hey" "Hey email"
remove_webapp "whatsapp" "WhatsApp"
remove_webapp "zoom" "Zoom"

echo ""
echo "━━━ Refreshing Application Menu ━━━"
# Refresh the application menu
update-desktop-database ~/.local/share/applications 2>/dev/null || true

# Remove keyboard shortcuts
if [[ ${#all_bindings_to_remove[@]} -gt 0 ]]; then
    echo ""
    echo "━━━ Removing Keyboard Shortcuts ━━━"
    remove_bindings_from_file "${all_bindings_to_remove[@]}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cleanup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Summary:"
echo "  • Removed unused applications and webapps"
echo "  • Cleaned up keyboard shortcuts from Hyprland config"
echo "  • Kept essential system tools"
echo "  • Freed up disk space"
echo ""
echo "You may want to also run:"
echo "  sudo pacman -Sc    # Clean package cache"
echo "  yay -Sc            # Clean AUR cache"
echo ""
echo "Reload Hyprland to apply shortcut changes:"
echo "  Super+Shift+R      # Reload Hyprland config"
echo ""
