#!/bin/bash
# Source: https://github.com/MNMaqsood/oh-my-zsh-installer/blob/main/install_oh_my_zsh.sh
# Exit on error
set -e

# Function to print messages
log() {
    echo -e "\e[32m$1\e[0m"
}

# Install Zsh
log "Installing Zsh..."
sudo apt update
sudo apt install -y zsh curl git

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

# Set up symlink
log "Setting up .zshrc symlink..."
cd ~ && ln -sf .config/nvim/zsh/.zshrc ~/.zshrc && cd -

# Set Zsh as the default shell
log "Setting Zsh as the default shell..."
chsh -s $(which zsh)

log "Zsh installation completed!"
