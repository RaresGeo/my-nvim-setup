#!/bin/bash
# AeroSpace module: tiling window manager (macOS only).
#
# Installs AeroSpace from its own Homebrew tap, links aerospace.toml, and
# starts it. It needs Accessibility permission, which macOS asks for on first
# launch.

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! is_macos; then
    error "This module only applies to macOS; nothing to do here."
    exit 1
fi

if (( ! SKIP_PACKAGES )) && [[ ! -d /Applications/AeroSpace.app ]]; then
    log "Installing AeroSpace..."
    # Homebrew refuses third-party taps until they are explicitly trusted.
    brew trust nikitabobko/tap 2>/dev/null || true
    brew install --cask nikitabobko/tap/aerospace
fi

log "Linking aerospace.toml..."
link aerospace/aerospace.toml "$HOME/.config/aerospace/aerospace.toml"
for script in "$MODULE_DIR"/bin/*; do
    link "aerospace/bin/$(basename "$script")" "$HOME/.local/bin/$(basename "$script")"
done

# AeroSpace hides windows on inactive workspaces by moving them off screen.
# Grouping by app keeps Mission Control usable with that.
defaults write com.apple.dock expose-group-apps -bool true
killall Dock 2>/dev/null || true

if pgrep -xq AeroSpace; then
    log "Reloading AeroSpace config..."
    aerospace reload-config || warn "Reload failed; run 'aerospace reload-config' to see why."
else
    log "Starting AeroSpace..."
    open -a AeroSpace || warn "Could not start AeroSpace."
fi

log "AeroSpace installation completed!"
info "First run only: grant AeroSpace Accessibility when macOS asks."
