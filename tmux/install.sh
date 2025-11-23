#!/bin/bash
# ~/.config/nvim/tmux/install.sh

# Exit on error
set -e

# Function to print messages
log() {
    echo -e "\e[32m$1\e[0m"
}

# Install tmux
log "Installing tmux..."
sudo apt update
sudo apt install -y tmux git

# Install TPM if not already installed
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    log "TPM is already installed at $HOME/.tmux/plugins/tpm. Skipping installation."
else
    log "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Set up symlink
log "Setting up .tmux.conf symlink..."
cd ~ && ln -sf .config/nvim/tmux/.tmux.conf ~/.tmux.conf && cd -

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
