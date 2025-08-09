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
    "$TERMINAL_EMULATOR" -e bash -c "$0; echo; read -n 1 -s -r -p ' Press any key to close this window...'"
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
REMOVE_EMPTY=false  # new flag for empty profiles

# Parse command-line arguments to enable optional modes
for arg in "$@"; do
  case "$arg" in
    --yes|-y)
      AUTO_CONFIRM=true
      ;;
    --all|-a)
      CLEAN_ALL=true
      ;;
    --yes-all|-ya|-ay)
      AUTO_CONFIRM=true
      CLEAN_ALL=true
      ;;
    --dry-run)
      DRY_RUN=true
      ;;
    --empty|-e)  # new option
      REMOVE_EMPTY=true
      ;;
    --help|-h)
      echo " FirefoxPWA Cache Cleaner"
      echo
      echo "Usage: pwaclean [options]"
      echo
      echo "Options:"
      echo "  --all, -a        Clean all profiles"
      echo "  --yes, -y        Skip confirmation prompts"
      echo "  --yes-all, -ya   Clean all profiles without confirmation"
      echo "  -ay              Same as --yes-all"
      echo "  --dry-run        Show what would be cleaned without deleting"
      echo "  --empty, -e      Delete empty profiles (no apps installed)"  # new option
      echo "  --help, -h       Show this help message"
      echo
      echo "If no options are provided, the script will prompt for profile selection."
      exit 0
      ;;
    *)
      echo "⚠️ Unknown option: $arg"
      exit 1
      ;;
  esac
done

# Safety confirmation for --empty option (ALWAYS ask, ignore AUTO_CONFIRM)
if $REMOVE_EMPTY; then
  echo
  echo "============================================================"
  echo "⚠️   D A N G E R O U S   O P E R A T I O N"
  echo "============================================================"
  echo " You are using the '--empty' option."
  echo
  echo " This will:"
  echo "   • Modify the configuration file:"
  echo "       $CONFIG_FILE"
  echo "   • Mark certain profiles as EMPTY (no apps installed)."
  echo "   • This change CANNOT be undone automatically."
  echo
  echo " A backup will be created before changes (unless --dry-run)."
  echo "============================================================"
  echo
  read -p "❓ Do you want to continue? (y/N): " CONFIRM
  if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "❌ Operation cancelled by user."
    exit 0
  fi
  echo
fi

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
  echo "❌ This script requires 'jq'."
  echo "Install it with: sudo apt install jq"
  exit 1
fi

# --- WARNING + BACKUP when using --empty (modifies config.json) ---
if $REMOVE_EMPTY; then
  if $DRY_RUN; then
    echo "⚠️  --empty used together with --dry-run: no changes will be made to '$CONFIG_FILE'. No backup created."
  else
    echo "⚠️  WARNING: --empty will modify '$CONFIG_FILE' (profiles JSON). A backup will be created before changes."
    BACKUP_FILE="${CONFIG_FILE}.bak_$(date +%F_%H-%M-%S)"
    if cp "$CONFIG_FILE" "$BACKUP_FILE"; then
      echo "📦 Backup created: $BACKUP_FILE"
    else
      echo "❌ Failed to create backup at '$BACKUP_FILE' — aborting to avoid data loss."
      exit 1
    fi
  fi
  echo
fi
# ----------------------------------------------------------------

echo "🔍 Scanning FirefoxPWA caches..."
echo

# Collect profile information
declare -A PROFILE_IDS
declare -A PROFILE_NAMES
declare -A PROFILE_SIZES
INDEX=1
TOTAL_SIZE=0

# Read profiles from config.son
for PROFILE in "$BASE_DIR"/*; do
  if [ -d "$PROFILE" ]; then
    PROFILE_ID=$(basename "$PROFILE")

    # Skip DEFAULT profile
    if [ "$PROFILE_ID" = "00000000000000000000000000" ]; then
      continue
    fi

    NAME=$(jq -r --arg ulid "$PROFILE_ID" '.profiles[$ulid].name // "(unnamed)"' "$CONFIG_FILE")

    # Calculate total size of cache-related directories
    SIZE=$(find "$PROFILE" -maxdepth 1 -type d \( \
      -name "cache2" -o \
      -name "startupCache" -o \
      -name "offlineCache" -o \
      -name "jumpListCache" -o \
      -name "minidumps" -o \
      -name "saved-telemetry-pings" -o \
      -name "datareporting" \
    \) -exec du -sb {} + 2>/dev/null | awk '{sum += $1} END {print sum}')

    HUMAN_SIZE=$(numfmt --to=iec ${SIZE:-0})

    APP_IDS=$(jq -r --arg ulid "$PROFILE_ID" '.profiles[$ulid].sites[]?' "$CONFIG_FILE")
    APP_COUNT=$(echo "$APP_IDS" | wc -l)

    PROFILE_IDS[$INDEX]="$PROFILE_ID"
    PROFILE_NAMES[$INDEX]="$NAME"
    PROFILE_SIZES[$INDEX]="$SIZE"

    # Profile main line
    echo "$INDEX) $NAME ($PROFILE_ID): $HUMAN_SIZE"

    # Only show sub-apps if there is more than one
    if [ "$APP_COUNT" -gt 1 ]; then
      for APP_ID in $APP_IDS; do
        APP_NAME=$(jq -r --arg id "$APP_ID" '.sites[$id].manifest.name // .sites[$id].config.name // "(unnamed)"' "$CONFIG_FILE")
        echo "   - $APP_NAME"
      done
    fi

    TOTAL_SIZE=$((TOTAL_SIZE + SIZE))
    INDEX=$((INDEX + 1))
  fi
done

HUMAN_TOTAL=$(numfmt --to=iec $TOTAL_SIZE)
echo
echo "📦 Total removable cache: $HUMAN_TOTAL"
echo

# Function to clean cache folders of a profile
clean_profile() {
  local PROFILE_PATH="$BASE_DIR/$1"
  for DIR_NAME in "${CLEAN_DIRS[@]}"; do
    DIR="$PROFILE_PATH/$DIR_NAME"
    if [ -d "$DIR" ]; then
      rm -rf "$DIR"/*
    fi
  done
}

# Confirmation prompt for cleaning
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

# If --empty is specified, process empty profiles first
if $REMOVE_EMPTY; then
  echo "🔍 Scanning for empty profiles (without installed apps)..."
  echo
  EMPTY_PROFILES=()

  # Get all profile IDs from JSON, excluding the default profile
  ALL_PROFILE_IDS=($(jq -r '.profiles | keys[] | select(. != "00000000000000000000000000")' "$CONFIG_FILE"))

  for ID in "${ALL_PROFILE_IDS[@]}"; do
    NAME=$(jq -r --arg ulid "$ID" '.profiles[$ulid].name' "$CONFIG_FILE")
    APP_IDS=$(jq -r --arg ulid "$ID" '.profiles[$ulid].sites[]?' "$CONFIG_FILE")
    PROFILE_PATH="$BASE_DIR/$ID"

    # Check if no apps and (folder doesn't exist OR folder is empty)
    if [ -z "$APP_IDS" ] && { [ ! -d "$PROFILE_PATH" ] || [ -z "$(ls -A "$PROFILE_PATH" 2>/dev/null)" ]; }; then
      EMPTY_PROFILES+=("$ID::$NAME")
    fi
  done

  if [ ${#EMPTY_PROFILES[@]} -eq 0 ]; then
    echo "❌ No empty profiles found."
    echo
  else
    echo "📂 Found ${#EMPTY_PROFILES[@]} empty profile(s):"
    for entry in "${EMPTY_PROFILES[@]}"; do
      IFS="::" read -r ID NAME <<< "$entry"
      echo " - $NAME ($ID)"
    done
    echo

    # Always ask unless user explicitly passed --yes
    if ! $AUTO_CONFIRM; then
      read -p "❓ Delete these profiles? (Y/n): " yn
      yn="${yn:-y}"
      echo
      if [[ ! "$yn" =~ ^[Yy]$ ]]; then
        echo "❌ Aborted empty profile removal."
        echo
        exit 0
      fi
    fi

    for entry in "${EMPTY_PROFILES[@]}"; do
      IFS="::" read -r ID NAME <<< "$entry"
      if $DRY_RUN; then
        echo "👀 Would delete profile: $NAME ($ID)"
      else
        rm -rf "$BASE_DIR/$ID"
        echo "✅ Deleted profile directory (if existed): $NAME ($ID)"
        tmpfile=$(mktemp)
        jq "del(.profiles[\"$ID\"])" "$CONFIG_FILE" > "$tmpfile" && mv "$tmpfile" "$CONFIG_FILE"
        echo "🗑️ Removed profile entry from config: $NAME ($ID)"
      fi
    done
    echo
  fi

  # Exit after processing --empty, unless cleaning cache is also requested separately
  [ "$CLEAN_ALL" = false ] && exit 0
fi

# Ask user to select profiles unless --all was passed
if $CLEAN_ALL; then
  SELECTION=("a")
else
  read -p "Enter the numbers of the apps to clean (e.g. 1 3 5, 'a' for all, 'n' for none): " -a SELECTION
  echo
fi

echo "🧹 Cleaning selected apps caches..."
echo
CLEARED=0

# Process cleaning of cache based on selection
if $CLEAN_ALL || [[ "${SELECTION[0]}" =~ ^(a|\*)$ ]]; then
  if ! $AUTO_CONFIRM; then
    read -p "❓ Do you want to clean *all* apps? (Y/n): " yn
    yn="${yn:-y}"
    if [[ ! "$yn" =~ ^[Yy]$ ]]; then
      echo "🚫 Cancelled cleaning all apps."
      exit 0
    fi
  fi
  for NUM in "${!PROFILE_IDS[@]}"; do
    PROFILE_ID="${PROFILE_IDS[$NUM]}"
    NAME="${PROFILE_NAMES[$NUM]}"
    SIZE="${PROFILE_SIZES[$NUM]}"
    if $DRY_RUN; then
      echo "👀 Would clean: $NAME"
    else
      clean_profile "$PROFILE_ID"
      CLEARED=$((CLEARED + SIZE))
      echo "✔ $NAME cleaned"
    fi
  done
elif [[ "${SELECTION[0]}" =~ ^(n|N)$ ]]; then
  echo "🚫 No apps selected. Nothing was cleaned."
  exit 0
else
  for NUM in "${SELECTION[@]}"; do
    PROFILE_ID="${PROFILE_IDS[$NUM]}"
    NAME="${PROFILE_NAMES[$NUM]}"
    SIZE="${PROFILE_SIZES[$NUM]}"
    if [ -n "$PROFILE_ID" ]; then
      if confirm_clean "$NAME"; then
        if $DRY_RUN; then
          echo "👀 Would clean: $NAME"
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

HUMAN_CLEARED=$(numfmt --to=iec $CLEARED)
echo
echo "✅ Total cache cleared: $HUMAN_CLEARED"
