#!/bin/bash
# OmniWM module: tiling window manager with Hyprland-style dwindle and Niri
# layouts (macOS only). Replaced the aerospace module once dwindle turned
# out to matter more than staying on a mature tool.
#
# Installs OmniWM from its own Homebrew cask, links settings.toml, and
# starts it. It needs Accessibility permission, which macOS asks for on
# first launch.
#
# Also installs a small watcher that activates Finder whenever you switch
# to an empty workspace. macOS always keeps some app frontmost regardless
# of which Space is visible, so without this an off-screen window on
# another workspace silently keeps eating your keystrokes.

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! is_macos; then
    error "This module only applies to macOS; nothing to do here."
    exit 1
fi

if (( ! SKIP_PACKAGES )) && [[ ! -d /Applications/OmniWM.app ]]; then
    log "Installing OmniWM..."
    brew install --cask omniwm
fi

log "Linking settings.toml..."
link omniwm/settings.toml "$HOME/.config/omniwm/settings.toml"

log "Linking the empty-workspace watcher..."
link omniwm/empty-workspace-focus "$HOME/.local/bin/omniwm-empty-workspace-focus"
chmod +x "$HOME/.local/bin/omniwm-empty-workspace-focus"

log "Installing the empty-workspace watcher as a login item..."
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.danielsetup.omniwm-empty-workspace-focus.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$LAUNCH_AGENT" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.danielsetup.omniwm-empty-workspace-focus</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/.local/bin/omniwm-empty-workspace-focus</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardErrorPath</key>
    <string>/tmp/omniwm-empty-workspace-focus.log</string>
</dict>
</plist>
PLIST

launchctl unload "$LAUNCH_AGENT" 2>/dev/null || true
launchctl load "$LAUNCH_AGENT"

if pgrep -xq OmniWM; then
    log "OmniWM already running; restart it to pick up settings.toml changes."
else
    log "Starting OmniWM..."
    open -a OmniWM || warn "Could not start OmniWM."
fi

log "OmniWM installation completed!"
info "First run only: grant OmniWM Accessibility when macOS asks."
info "Caps Lock is OmniWM's Hyper key trigger; see README.md for the full binding list."
