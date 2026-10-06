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

# typescript-language-server drives TypeScript's own tsserver.js and ships no
# compiler itself. Homebrew's `typescript` is the native 7.x port now, which has
# no tsserver.js anywhere in it, so the server's bundled copy is a dead end and
# it exits at startup. 6.0.3 is the last release that still ships tsserver.js;
# lsp/ts_ls.lua prefers whatever TypeScript a project installs and falls back to
# this one, which is what makes single files and uninstalled projects work.
TSSERVER_VERSION="6.0.3"
TSSERVER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/tsserver"
TSSERVER_PKG_JSON="$TSSERVER_DIR/node_modules/typescript/package.json"

if ! command -v typescript-language-server &>/dev/null; then
    warn "typescript-language-server is not installed; TypeScript LSP will not start."
    warn "  macOS: brew install typescript-language-server"
    warn "  Arch:  sudo pacman -S typescript-language-server"
fi

if [[ " $* " == *" --no-plugins "* ]]; then
    log "Skipping the fallback TypeScript install (--no-plugins)."
elif ! command -v npm &>/dev/null; then
    warn "npm is not installed; skipping the fallback TypeScript for typescript-language-server."
elif [[ "$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' "$TSSERVER_PKG_JSON" 2>/dev/null | head -1)" == "$TSSERVER_VERSION" ]]; then
    log "Fallback TypeScript $TSSERVER_VERSION already installed."
else
    log "Installing fallback TypeScript $TSSERVER_VERSION for typescript-language-server..."
    mkdir -p "$TSSERVER_DIR"
    npm install --silent --no-fund --no-audit --prefix "$TSSERVER_DIR" "typescript@$TSSERVER_VERSION" || \
        warn "Fallback TypeScript install failed; ts_ls will only work where a project installs TypeScript."
fi

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
