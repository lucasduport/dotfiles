#!/usr/bin/env bash
# defaults.sh — macOS system settings that differ from a fresh install.
# Captured from the current Mac; re-run any time, it is idempotent.
#
#   bash macos/defaults.sh
#
# Find a setting to add: `defaults read > before.txt`, change it in System
# Settings, `defaults read > after.txt`, then `diff before.txt after.txt`.

set -euo pipefail

# ── Appearance ────────────────────────────────────────────────────────────────
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# ── Keyboard ──────────────────────────────────────────────────────────────────
# Fastest key repeat, short delay before it kicks in (UI minimums: 2 and 15).
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
# Holding a key repeats it instead of showing the accent picker (vim hjkl).
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ── Text input: no autocorrect or smart punctuation ───────────────────────────
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# ── Keyboard shortcuts: disable macOS defaults ────────────────────────────────
# IDs from com.apple.symbolichotkeys. AeroSpace and Raycast own these keys.
# Left enabled: Show Desktop (36, 37), 56, move window to space (80, 82).
hotkeys_off=(
  7 8 9 10 11 12 13 57           # Keyboard navigation: focus menu bar, Dock, windows… (⌃F1–F8)
  15 16 17 18 19 20 21 22 23 24 25 26  # Accessibility: Zoom, contrast
  59 162                         # VoiceOver (⌘F5), accessibility controls (⌥⌘F5)
  27                             # Move focus to next window (⌘`)
  28 29 30 31 184                # Screenshots (⇧⌘3, ⇧⌘4, ⇧⌘5)
  32 33                          # Mission Control, application windows (⌃↑, ⌃↓)
  79 81 118                      # Switch space left/right (⌃←, ⌃→), desktop 1 (⌃1)
  52                             # Toggle Dock hiding (⌥⌘D)
  53 54                          # Display brightness
  60 61                          # Input sources (⌃Space, ⌃⌥Space)
  64 65                          # Spotlight (⌘Space, ⌥⌘Space) — Raycast instead
  98                             # Show Help menu (⇧⌘/)
  190                            # Quick Note (fn Q)
  237 238 239 240 241 242 243 244 245 246 247 248 249 250 251  # Window tiling (fn ⌃ …)
  159 164 175 215 216 217 218 219 222 223 224 225 226 227 228 229 230 231 232
  233 235 256 257 258 260        # Misc: Notification Center, Focus, Stage Manager…
)
for id in "${hotkeys_off[@]}"; do
  defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
    -dict-add "$id" "<dict><key>enabled</key><false/></dict>"
done

# ── Mouse & trackpad ──────────────────────────────────────────────────────────
# Pointer speed (System Settings slider max is 3.0).
defaults write NSGlobalDomain com.apple.mouse.scaling -float 3
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2
# Tap to click.
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ── Dock ──────────────────────────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true
# Show the hidden Dock instantly, with a quick slide.
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock tilesize -float 45
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool false
defaults write com.apple.dock launchanim -bool false
# Bottom-right hot corner: off (macOS default is Quick Note).
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 0

# ── Spaces & Mission Control (recommended by AeroSpace) ──────────────────────
# Don't reorder spaces by most recent use.
defaults write com.apple.dock mru-spaces -bool false
# Group windows by app in Mission Control (AeroSpace hides windows off-screen).
defaults write com.apple.dock expose-group-apps -bool true
# One space across all displays ("Displays have separate Spaces" off). Log out.
defaults write com.apple.spaces spans-displays -bool true

# ── Window Manager ────────────────────────────────────────────────────────────
# No margins around tiled windows (AeroSpace handles gaps).
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
# No native tiling when dragging windows to screen edges or holding ⌥.
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false
defaults write com.apple.WindowManager EnableTilingOptionAccelerator -bool false
# Clicking the wallpaper doesn't hide every window.
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# ── Finder ────────────────────────────────────────────────────────────────────
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
# List view, folders first, search the current folder.
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
defaults write com.apple.finder _FXSortFoldersFirst -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# No .DS_Store on network shares or USB drives.
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
chflags nohidden ~/Library

# ── Save dialogs ──────────────────────────────────────────────────────────────
# Save to disk rather than iCloud, with the expanded dialog.
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# ── Screenshots ───────────────────────────────────────────────────────────────
mkdir -p ~/Pictures/Screenshots
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Reload preferences so shortcuts and input settings apply without a log out.
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
  &>/dev/null || true
killall Dock Finder SystemUIServer &>/dev/null || true
echo "macOS defaults applied. Pointer speed and Spaces changes may need a log out."
