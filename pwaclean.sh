#!/bin/bash
# Relaunching in terminal if not running interactively
if [[ ! -t 1 ]]; then
    if [[ $XDG_CURRENT_DESKTOP == *KDE* ]]; then
        TERMINAL_EMULATOR=$(command -v konsole)
    elif [[ $XDG_CURRENT_DESKTOP == *GNOME* ]]; then
        TERMINAL_EMULATOR=$(command -v gnome-terminal)
    else
        TERMINAL_EMULATOR=$(command -v x-terminal-emulator || command -v gnome-terminal || command -v konsole || command -v xfce4-terminal || command -v xterm)
    fi

    if [ -n "$TERMINAL_EMULATOR" ]; then
        "$TERMINAL_EMULATOR" -e "$0"
        exit
    else
        echo "❌ Could not find a terminal emulator to relaunch."
        exit 1
    fi
fi

# Define paths for profiles and config
BASE_DIR="$HOME/.local/share/firefoxpwa/profiles"
CONFIG_FILE="$HOME/.local/share/firefoxpwa/config.json"

# Check existence
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

echo "🔍 Scanning FirefoxPWA cache..."
echo

# Build profile list with name, size, and apps
declare -A PROFILE_IDS
declare -A PROFILE_NAMES
declare -A PROFILE_SIZES

INDEX=1
TOTAL_SIZE=0

for PROFILE in "$BASE_DIR"/*; do
    if [ -d "$PROFILE" ]; then
        PROFILE_ID=$(basename "$PROFILE")
        NAME=$(jq -r --arg ulid "$PROFILE_ID" '.profiles[$ulid].name // "(unnamed)"' "$CONFIG_FILE")
        SIZE=$(du -sb "$PROFILE"/cache2 "$PROFILE"/startupCache "$PROFILE"/offlineCache 2>/dev/null | awk '{sum += $1} END {print sum}')
        HUMAN_SIZE=$(numfmt --to=iec $SIZE)

        # Get associated app IDs
        APP_IDS=$(jq -r --arg ulid "$PROFILE_ID" '.profiles[$ulid].sites[]?' "$CONFIG_FILE")
        APP_COUNT=$(echo "$APP_IDS" | wc -l)

        PROFILE_IDS[$INDEX]="$PROFILE_ID"
        PROFILE_NAMES[$INDEX]="$NAME"
        PROFILE_SIZES[$INDEX]="$SIZE"

        if [ "$APP_COUNT" -gt 1 ]; then
            echo "$INDEX) $NAME ($PROFILE_ID): $HUMAN_SIZE — $APP_COUNT apps"
            for APP_ID in $APP_IDS; do
                APP_NAME=$(jq -r --arg id "$APP_ID" '
                    .sites[$id].manifest.name //
                    .sites[$id].config.name //
                    "(unnamed)"' "$CONFIG_FILE")
                echo "    - $APP_NAME"
            done
        else
            echo "$INDEX) $NAME ($PROFILE_ID): $HUMAN_SIZE"
        fi

        TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
        INDEX=$((INDEX + 1))
    fi
done

echo
HUMAN_TOTAL=$(numfmt --to=iec $TOTAL_SIZE)
echo "📦 Total cache that can be cleared: $HUMAN_TOTAL"
echo

# Prompt user for selection
read -p "Enter the numbers of the profiles to clean (e.g. 1 3 5, 'a' for all, 'n' for none): " -a SELECTION

echo
echo "🧹 Cleaning selected profile caches..."

CLEARED=0

# If user selects 'n' or 'N', cancel
if [[ "${SELECTION[0]}" =~ ^(n|N)$ ]]; then
    echo "🚫 No profiles selected. No cache was cleared."
    exit 0
fi

# If user selects 'a' or '*', clean all
if [[ "${SELECTION[0]}" =~ ^(a|\*)$ ]]; then
    for NUM in "${!PROFILE_IDS[@]}"; do
        PROFILE_ID="${PROFILE_IDS[$NUM]}"
        NAME="${PROFILE_NAMES[$NUM]}"
        SIZE="${PROFILE_SIZES[$NUM]}"

        rm -rf "$BASE_DIR/$PROFILE_ID/cache2"/*
        rm -rf "$BASE_DIR/$PROFILE_ID/startupCache"/*
        rm -rf "$BASE_DIR/$PROFILE_ID/offlineCache"/*
        CLEARED=$((CLEARED + SIZE))
        echo "✔ $NAME cleaned"
    done
else
    for NUM in "${SELECTION[@]}"; do
        PROFILE_ID="${PROFILE_IDS[$NUM]}"
        NAME="${PROFILE_NAMES[$NUM]}"
        SIZE="${PROFILE_SIZES[$NUM]}"

        if [ -n "$PROFILE_ID" ]; then
            rm -rf "$BASE_DIR/$PROFILE_ID/cache2"/*
            rm -rf "$BASE_DIR/$PROFILE_ID/startupCache"/*
            rm -rf "$BASE_DIR/$PROFILE_ID/offlineCache"/*
            CLEARED=$((CLEARED + SIZE))
            echo "✔ $NAME cleaned"
        else
            echo "⚠️ Invalid selection: $NUM"
        fi
    done
fi

echo
HUMAN_CLEARED=$(numfmt --to=iec $CLEARED)
echo "✅ Total cache cleared: $HUMAN_CLEARED"
