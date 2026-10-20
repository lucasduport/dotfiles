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

# ── Dock ──────────────────────────────────────────────────────────────────────
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock tilesize -float 45
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock minimize-to-application -bool false
# Bottom-right hot corner: off (macOS default is Quick Note).
defaults write com.apple.dock wvous-br-corner -int 1
defaults write com.apple.dock wvous-br-modifier -int 0

# ── Finder ────────────────────────────────────────────────────────────────────
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# ── Trackpad: tap to click ────────────────────────────────────────────────────
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# ── Window Manager ────────────────────────────────────────────────────────────
# No margins around tiled windows (AeroSpace handles gaps).
defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false

killall Dock Finder SystemUIServer &>/dev/null || true
echo "macOS defaults applied. Trackpad and appearance changes may need a log out."
