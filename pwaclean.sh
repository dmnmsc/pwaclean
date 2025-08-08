#!/bin/bash

# Relaunch in terminal if not running interactively
if [[ ! -t 1 ]]; then
    if [[ $XDG_CURRENT_DESKTOP == *KDE* ]]; then
        TERMINAL_EMULATOR=$(command -v konsole)
    elif [[ $XDG_CURRENT_DESKTOP == *GNOME* ]]; then
        TERMINAL_EMULATOR=$(command -v gnome-terminal)
    else
        TERMINAL_EMULATOR=$(command -v x-terminal-emulator || command -v gnome-terminal || command -v konsole || command -v xfce4-terminal || command -v xterm)
    fi

    if [ -n "$TERMINAL_EMULATOR" ]; then
        "$TERMINAL_EMULATOR" -e bash -c "$0; echo; read -n 1 -s -r -p '🔚 Press any key to close this window...'"
        exit
    else
        echo "❌ Could not find a terminal emulator to relaunch."
        exit 1
    fi
fi

# Paths to profiles and config
BASE_DIR="$HOME/.local/share/firefoxpwa/profiles"
CONFIG_FILE="$HOME/.local/share/firefoxpwa/config.json"
AUTO_CONFIRM=false
CLEAN_ALL=false
DRY_RUN=false

# Parse command-line arguments to enable optional modes
for arg in "$@"; do
    case "$arg" in
        --yes|-y) AUTO_CONFIRM=true ;;
        --all|-a) CLEAN_ALL=true ;;
        --yes-all|-ya|-ay) AUTO_CONFIRM=true; CLEAN_ALL=true ;;
        --dry-run) DRY_RUN=true ;;
        --help|-h)
            echo "🧹 FirefoxPWA Cache Cleaner"
            echo
            echo "Usage: pwaclean [options]"
            echo
            echo "Options:"
            echo "  --all, -a         Clean all profiles"
            echo "  --yes, -y         Skip confirmation prompts"
            echo "  --yes-all, -ya    Clean all profiles without confirmation"
            echo "  -ay               Same as --yes-all"
            echo "  --dry-run         Show what would be cleaned without deleting"
            echo "  --help, -h        Show this help message"
            echo
            echo "If no options are provided, the script will prompt for profile selection."
            exit 0
            ;;
        *) echo "⚠️ Unknown option: $arg"; exit 1 ;;
    esac
done

# Folders considered safe to clear inside each profile
readonly CLEAN_DIRS=("cache2" "startupCache" "offlineCache" "jumpListCache" "minidumps" "saved-telemetry-pings" "datareporting")

# Verify required files and tools
if [ ! -d "$BASE_DIR" ]; then
    echo "❌ Profile directory not found: $BASE_DIR"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ config.json not found: $CONFIG_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ This script requires 'jq'. Install it with: sudo apt install jq"
    exit 1
fi

echo "🔍 Scanning FirefoxPWA caches..."
echo

# Collect profile information
declare -A PROFILE_IDS
declare -A PROFILE_NAMES
declare -A PROFILE_SIZES

INDEX=1
TOTAL_SIZE=0

for PROFILE in "$BASE_DIR"/*; do
    if [ -d "$PROFILE" ]; then
        PROFILE_ID=$(basename "$PROFILE")
        NAME=$(jq -r --arg ulid "$PROFILE_ID" '.profiles[$ulid].name // "(unnamed)"' "$CONFIG_FILE")

        # Calculate total size of all CLEAN_DIRS in the profile
        SIZE=0
        for DIR_NAME in "${CLEAN_DIRS[@]}"; do
            DIR="$PROFILE/$DIR_NAME"
            if [ -d "$DIR" ]; then
                DIR_SIZE=$(du -sb "$DIR" 2>/dev/null | awk '{print $1}')
                SIZE=$((SIZE + DIR_SIZE))
            fi
        done

        HUMAN_SIZE=$(numfmt --to=iec $SIZE)

        # Get associated app IDs
        APP_IDS=$(jq -r --arg ulid "$PROFILE_ID" '.profiles[$ulid].sites[]?' "$CONFIG_FILE")
        APP_COUNT=$(echo "$APP_IDS" | wc -l)

        PROFILE_IDS[$INDEX]="$PROFILE_ID"
        PROFILE_NAMES[$INDEX]="$NAME"
        PROFILE_SIZES[$INDEX]="$SIZE"

        echo "$INDEX) $NAME ($PROFILE_ID): $HUMAN_SIZE"

        if [ "$APP_COUNT" -gt 1 ]; then
            for APP_ID in $APP_IDS; do
                APP_NAME=$(jq -r --arg id "$APP_ID" '
                    .sites[$id].manifest.name //
                    .sites[$id].config.name //
                    "(unnamed)"' "$CONFIG_FILE")
                echo "    - $APP_NAME"
            done
        fi

        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        INDEX=$((INDEX + 1))
    fi
done

echo
HUMAN_TOTAL=$(numfmt --to=iec $TOTAL_SIZE)
echo "📦 Total removable cache: $HUMAN_TOTAL"
echo

# Ask user to select profiles unless --all was passed
if $CLEAN_ALL; then
    SELECTION=("a")
else
    read -p "Enter the numbers of the profiles to clean (e.g. 1 3 5, 'a' for all, 'n' for none): " -a SELECTION
fi

echo
echo "🧹 Cleaning selected profile caches..."
echo

CLEARED=0

# Clean a profile's cache folders
clean_profile() {
    local PROFILE_PATH="$BASE_DIR/$1"
    for DIR_NAME in "${CLEAN_DIRS[@]}"; do
        DIR="$PROFILE_PATH/$DIR_NAME"
        if [ -d "$DIR" ]; then
            rm -rf "$DIR"/*
        fi
    done
}

# Confirm Clean
confirm_clean() {
    local NAME="$1"
    if $AUTO_CONFIRM; then
        return 0
    fi
    while true; do
        read -p "❓ Do you want to clean '$NAME'? (Y/n): " yn
        yn="${yn:-y}"
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
            *) echo "⚠️ Please answer y or n." ;;
        esac
    done
}

# Process selection
if $CLEAN_ALL || [[ "${SELECTION[0]}" =~ ^(a|\*)$ ]]; then
    if ! $AUTO_CONFIRM; then
        read -p "❓ Do you want to clean *all* profiles? (Y/n): " yn
        yn="${yn:-y}"
        if [[ ! "$yn" =~ ^[Yy]$ ]]; then
            echo "🚫 Cancelled cleaning all profiles."
            exit 0
        fi
    fi
    for NUM in "${!PROFILE_IDS[@]}"; do
        PROFILE_ID="${PROFILE_IDS[$NUM]}"
        NAME="${PROFILE_NAMES[$NUM]}"
        SIZE="${PROFILE_SIZES[$NUM]}"
        if $DRY_RUN; then
            echo "🧪 Would clean: $NAME"
        else
            clean_profile "$PROFILE_ID"
            CLEARED=$((CLEARED + SIZE))
            echo "✔ $NAME cleaned"
        fi
    done
elif [[ "${SELECTION[0]}" =~ ^(n|N)$ ]]; then
    echo "🚫 No profiles selected. Nothing was cleaned."
    exit 0
else
    for NUM in "${SELECTION[@]}"; do
        PROFILE_ID="${PROFILE_IDS[$NUM]}"
        NAME="${PROFILE_NAMES[$NUM]}"
        SIZE="${PROFILE_SIZES[$NUM]}"

        if [ -n "$PROFILE_ID" ]; then
            if confirm_clean "$NAME"; then
                if $DRY_RUN; then
                    echo "🧪 Would clean: $NAME"
                else
                    clean_profile "$PROFILE_ID"
                    CLEARED=$((CLEARED + SIZE))
                    echo "✔ $NAME cleaned"
                fi
            else
                echo "⏭ Skipped: $NAME"
            fi
        else
            echo "⚠️ Invalid selection: $NUM"
        fi
    done
fi

echo
HUMAN_CLEARED=$(numfmt --to=iec $CLEARED)
echo "✅ Total cache cleared: $HUMAN_CLEARED"
