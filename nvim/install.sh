#!/bin/bash
# Neovim module: symlink the config into ~/.config/nvim and bootstrap plugins.

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"
install_packages "nvim_essentials"

NVIM_CONFIG="$HOME/.config/nvim"

# This repo used to live at ~/.config/nvim itself. If it still does, linking
# would point the config at itself; the repo has to move first.
if [[ "$DOTFILES_DIR" == "$NVIM_CONFIG" ]]; then
    error "This repo is checked out at $NVIM_CONFIG, which is where the nvim"
    error "config needs to be symlinked. Move the repo elsewhere first, e.g.:"
    error "  mv $NVIM_CONFIG ~/.config/dotfiles && ~/.config/dotfiles/install.sh nvim"
    exit 1
fi

log "Setting up neovim config symlink..."
link nvim "$NVIM_CONFIG"

# Nothing Omarchy-specific to install here: the colorscheme is resolved at
# runtime from ~/.local/state/omarchy (see nvim/lua/plugins/colorscheme.lua), and
# the hook that hotswaps a running instance belongs to the omarchy module.

# Bootstrap lazy.nvim and install plugins without opening a UI. Skippable
# because it needs the network and takes a while.
if [[ " $* " == *" --no-plugins "* ]]; then
    log "Skipping plugin bootstrap (--no-plugins)."
elif command -v nvim &>/dev/null; then
    log "Bootstrapping lazy.nvim plugins (this can take a minute)..."
    nvim --headless "+Lazy! restore" +qa </dev/null 2>&1 | tail -5 || \
        warn "Plugin bootstrap reported errors; open nvim and run :Lazy to check."
else
    warn "nvim is not installed; skipping plugin bootstrap."
fi

log "Neovim installation completed!"
