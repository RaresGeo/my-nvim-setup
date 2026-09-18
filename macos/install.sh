#!/bin/bash
# macOS module: the base layer for a Mac that lives in the terminal.
#
#   - CLI tools from the Brewfile
#   - Alacritty config, built from source with --with-alacritty
#   - a static snapshot of the Omarchy theme, which nvim, zsh and Alacritty read
#   - a few system defaults (defaults.sh)
#
# Key remaps and window management are separate modules: karabiner, aerospace.
#
# Flags:
#   --no-packages      skip `brew bundle`
#   --no-defaults      skip defaults.sh
#   --with-alacritty   build Alacritty from source (build-alacritty.sh)

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"

if ! is_macos; then
    error "This module only applies to macOS; nothing to do here."
    exit 1
fi

if (( SKIP_PACKAGES )); then
    log "Skipping brew bundle (--no-packages)."
elif check_pkg_manager_installed brew; then
    log "Installing Brewfile packages..."
    brew bundle --file "$MODULE_DIR/Brewfile"
else
    exit 1
fi

log "Linking Alacritty config..."
link macos/alacritty/alacritty.toml "$HOME/.config/alacritty/alacritty.toml"

# nvim, zsh and Alacritty read colors from Omarchy's current-theme directory.
# There is no Omarchy here to populate it, so point it at a checked-in snapshot.
log "Linking theme snapshot..."
link macos/theme/kanagawa "$HOME/.local/state/omarchy/current/theme"

if [[ " $* " == *" --with-alacritty "* ]]; then
    "$MODULE_DIR/build-alacritty.sh"
elif [[ ! -d "$HOME/Applications/Alacritty.app" && ! -d /Applications/Alacritty.app ]]; then
    warn "Alacritty is not installed. Build it with: ./install.sh macos --with-alacritty"
fi

if [[ " $* " == *" --no-defaults "* ]]; then
    log "Skipping macOS defaults (--no-defaults)."
else
    log "Applying macOS defaults..."
    # shellcheck source=macos/defaults.sh
    source "$MODULE_DIR/defaults.sh"
fi

log "macOS installation completed!"
