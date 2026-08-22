#!/bin/bash
# Tmux module: symlink ~/.tmux.conf, install TPM, install plugins.

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"
install_packages "tmux_essentials"

# Install TPM if not already installed
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    log "TPM is already installed at $HOME/.tmux/plugins/tpm. Skipping installation."
else
    log "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

log "Setting up .tmux.conf symlink..."
link tmux/.tmux.conf "$HOME/.tmux.conf"

# Anything Omarchy-specific (theme template, config precedence) lives in
# tmux/omarchy.sh and only runs on an Omarchy host.
run_integration omarchy

# Handle tmux plugin installation
if [ -n "$TMUX" ]; then
    # We're in tmux, source the config
    log "Sourcing tmux configuration..."
    tmux source ~/.tmux.conf
else
    # Not in tmux, kill all existing sessions to force config reload
    log "Killing existing tmux sessions..."
    tmux kill-server 2>/dev/null || true
fi

# Install plugins
log "Installing tmux plugins..."
tmux new-session -d -s tmp_install_session
~/.tmux/plugins/tpm/bin/install_plugins
tmux kill-session -t tmp_install_session

log "Tmux installation completed!"
log "Start tmux with 'tmux' or attach to existing session with 'tmux attach'."
