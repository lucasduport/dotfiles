#!/usr/bin/env bash
# vorssaint.sh — version Vorssaint settings in this repo.
#
#   bash macos/vorssaint.sh save     live prefs → macos/vorssaint-settings.plist
#   bash macos/vorssaint.sh load     macos/vorssaint-settings.plist → live prefs
#
# The file uses Vorssaint's own backup format ({settings, vorssaintBackup*}),
# so it can also be loaded from Vorssaint → Settings → Import.
#
# `save` drops keys that are machine-specific or private: audio device UIDs
# (they embed Bluetooth MAC addresses), external display IDs, window sizes,
# one-shot migration flags and the command bar habit key. This repo is public.

set -euo pipefail

DOMAIN="com.vorssaint.utils"
APP="Vorssaint"
FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/vorssaint-settings.plist"
PB=/usr/libexec/PlistBuddy

DROP_KEYS=(
  audioPriorityDeviceNames
  audioPriorityInputUIDs
  audioPriorityOutputUIDs
  brightnessDDCWriteOnlyPaths
  brightnessDDCWriteOnlyPathsRechecked
  bluetoothSleepRestorePending
  commandBarQueryHabitKey
  lastUpdateIntroVersion
  settingsWindowHeight
  settingsWindowWidth
  shelfItems
  supportUpdateIntroVersion
  updateHighlightsSeenVersion
)

save() {
  local tmp settings
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  settings="$tmp/settings.plist"

  defaults export "$DOMAIN" "$settings"
  plutil -convert xml1 "$settings"

  local key
  for key in "${DROP_KEYS[@]}"; do
    "$PB" -c "Delete :$key" "$settings" &>/dev/null || true
  done
  # AppKit window/panel state and one-shot migration flags.
  while read -r key; do
    "$PB" -c "Delete :$key" "$settings" &>/dev/null || true
  done < <(plutil -p "$settings" | sed -n 's/^  "\([^"]*\)" => .*/\1/p' \
             | grep -E '^NS|Migrated$|Initialized$')

  local version
  version="$(defaults read /Applications/Vorssaint.app/Contents/Info CFBundleShortVersionString 2>/dev/null || echo unknown)"
  plutil -create xml1 "$tmp/backup.plist"
  "$PB" -c "Add :settings dict" \
        -c "Merge $settings :settings" \
        -c "Add :vorssaintBackupAppVersion string $version" \
        -c "Add :vorssaintBackupVersion integer 1" \
        "$tmp/backup.plist" >/dev/null
  mv "$tmp/backup.plist" "$FILE"
  echo "Saved $(plutil -extract settings raw -o - "$FILE" | wc -l | tr -d ' ') keys → $FILE"
}

load() {
  [[ -f "$FILE" ]] || { echo "No $FILE — run 'save' on a configured Mac first." >&2; exit 1; }
  local tmp running=false
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  plutil -extract settings xml1 -o "$tmp/settings.plist" "$FILE"
  # Keep machine-local keys (audio devices, displays) already on this Mac:
  # repo values win, anything only present locally survives.
  if defaults export "$DOMAIN" "$tmp/local.plist" 2>/dev/null; then
    "$PB" -c "Merge $tmp/local.plist" "$tmp/settings.plist" >/dev/null 2>&1 || true
  fi

  # A running app rewrites its prefs on quit and would undo the import.
  if pgrep -xq "$APP"; then
    running=true
    osascript -e "quit app \"$APP\"" 2>/dev/null || true
    sleep 2
  fi
  defaults import "$DOMAIN" "$tmp/settings.plist"
  echo "Loaded Vorssaint settings from $FILE"
  if $running; then open -a "$APP"; fi
}

case "${1:-}" in
  save) save ;;
  load) load ;;
  *) echo "usage: $0 save|load" >&2; exit 2 ;;
esac
