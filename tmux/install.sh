#!/bin/bash

# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Set up symlink
cd ~ && ln -sf .config/nvim/tmux/.tmux.conf ~/.tmux.conf && cd -

# Check if we're in a tmux session
if [ -n "$TMUX" ]; then
    # We're in tmux, source the config
    tmux source ~/.tmux.conf
else
    # Not in tmux, kill all existing sessions to force config reload
    tmux kill-server 2>/dev/null || true
fi

# Start a detached tmux session to install plugins
tmux new-session -d -s tmp_install_session
~/.tmux/plugins/tpm/bin/install_plugins
tmux kill-session -t tmp_install_session
