#!/bin/bash
# This script restores the configuration files from the dotfiles repository to the ~/.config directory.
# If new folders are added to the dotfiles repository, they should be added to this script.
# It also backs up the existing configuration files to the ~/.config directory.

DOTFILES_DIR=~/.dotfiles
CONFIG_DIR=~/.config

# Backup the existing configuration files
mv $CONFIG_DIR/hypr $CONFIG_DIR/_config_backup/hypr.backup
mv $CONFIG_DIR/waybar $CONFIG_DIR/_config_backup/waybar.backup
mv $CONFIG_DIR/bash $CONFIG_DIR/_config_backup/bash.backup
mv $HOME/.bashrc $HOME/._config_backup/bashrc.backup

# Create the configuration file directories if they don't exist
mkdir -p $CONFIG_DIR/hypr
mkdir -p $CONFIG_DIR/waybar
mkdir -p $CONFIG_DIR/bash

# Undo linking all of the dotfiles before restoring them
stow --D -v -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
stow --D -v -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
stow --D -v -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
stow --D -v -n -d $DOTFILES_DIR -t ~ bashrc

# Restore the configuration files from the dotfiles repository
stow -v -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
stow -v -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
stow -v -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
stow --dotfiles -v -d $DOTFILES_DIR -t ~ bashrc

# Install microsoft-edge-stable-bin from AUR and configure as default browser
sudo pacman -S microsoft-edge-stable-bin
xdg-settings set default-web-browser microsoft-edge-stable-bin.desktop