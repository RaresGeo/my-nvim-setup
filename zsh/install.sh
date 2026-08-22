#!/bin/bash
# Zsh module: oh-my-zsh + plugins, symlink ~/.zshrc, make zsh the login shell.
# Original oh-my-zsh bootstrap adapted from
# https://github.com/MNMaqsood/oh-my-zsh-installer

set -e

source "$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/package-manager.sh"
module_init "${BASH_SOURCE[0]}"

parse_install_flags "$@"
install_packages "zsh_essentials"

# Install Oh My Zsh if not already installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    log "Oh My Zsh is already installed at $HOME/.oh-my-zsh. Skipping installation."
else
    log "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Install Zsh autosuggestions
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    log "Installing Zsh autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
else
    log "Zsh autosuggestions already installed. Skipping."
fi

# Install Zsh syntax highlighting
if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    log "Installing Zsh syntax highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
else
    log "Zsh syntax highlighting already installed. Skipping."
fi

log "Setting up .zshrc symlink..."
link zsh/.zshrc "$HOME/.zshrc"

run_integration omarchy

# Set Zsh as the default shell
if [[ "$SHELL" == *zsh ]]; then
    log "Zsh is already the default shell. Skipping chsh."
else
    log "Setting Zsh as the default shell..."
    chsh -s "$(command -v zsh)"
fi

log "Zsh installation completed!"
