#!/bin/bash
# macOS system defaults. Sourced by macos/install.sh; skip with --no-defaults.
# Per-user and reversible with `defaults delete <domain> <key>`.

# omarchy/hypr/input.lua: repeat_rate = 40, repeat_delay = 600. macOS counts in
# 15 ms ticks.
defaults write -g KeyRepeat -int 2
defaults write -g InitialKeyRepeat -int 40
# Holding hjkl should repeat, not open the accent picker.
defaults write -g ApplePressAndHoldEnabled -bool false

# Ctrl+Cmd+drag moves a window from anywhere inside it.
defaults write -g NSWindowShouldDragOnGesture -bool true

mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

# Let Finder be quit (Cmd+Q) like any other app, so it stops sitting in Cmd+Tab
# when no Finder window is open. Clicking its Dock icon brings it back. Desktop
# icons are hidden too: Finder draws them, and nothing lives there anyway.
defaults write com.apple.finder QuitMenuItem -bool true
defaults write com.apple.finder CreateDesktop -bool false

# The keyboard layout. This Mac's internal keyboard reports itself as British,
# so macOS chose the British layout at setup -- which puts £ on Shift+3, " on
# Shift+2 and @ on Shift+', while everything in this repo assumes the US
# positions. Not a `defaults write`: the running input system owns that domain,
# so the change has to go through Text Input Services. See keyboard-layout.sh,
# which is also how to go back.
"$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/keyboard-layout.sh" ||
    echo "WARNING: keyboard layout unchanged; run macos/keyboard-layout.sh to see why" >&2

killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true
