#!/bin/bash
# This script restores the configuration files from the dotfiles repository to the ~/.config directory.
# If new folders are added to the dotfiles repository, they should be added to this script.
# It also backs up the existing configuration files to the ~/.config directory.

DOTFILES_DIR=~/.dotfiles
CONFIG_DIR=~/.config
BACKUP_DIR=$HOME/.config_backup

# Flags (defaults)
VERBOSE=0
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -h        Show this help and exit
  -v        Verbose output
  -n        Dry run (print commands instead of executing)
EOF
  exit "${1:-0}"
}

# Parse short options
while getopts ":hvn" opt; do
  case "$opt" in
    h) usage 0 ;;
    v) VERBOSE=1 ;;
    n) DRY_RUN=1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage 2 ;;
  esac
done
shift $((OPTIND - 1))

# Helpers
run() { if [ "$DRY_RUN" -eq 1 ]; then echo "+ $*"; else "$@"; fi; }
log() { [ "$VERBOSE" -eq 1 ] && echo "$*"; }

STOW_N=$([ "$DRY_RUN" -eq 1 ] && echo "-n")
STOW_V=$([ "$VERBOSE" -eq 1 ] && echo "-v")

# Create the backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Backup the existing configuration files
run mv $CONFIG_DIR/alacritty $BACKUP_DIR/alacritty
run mv $CONFIG_DIR/bash $BACKUP_DIR/bash
run mv $CONFIG_DIR/hypr $BACKUP_DIR/hypr
run mv $CONFIG_DIR/waybar $BACKUP_DIR/waybar
run mv $CONFIG_DIR/starship.toml $BACKUP_DIR/starship.toml
run mv $HOME/.bashrc $BACKUP_DIR/.bashrc

# Create the configuration file directories if they don't exist
run mkdir -p $CONFIG_DIR/alacritty
run mkdir -p $CONFIG_DIR/bash
run mkdir -p $CONFIG_DIR/hypr
run mkdir -p $CONFIG_DIR/waybar

# Undo linking all of the dotfiles before restoring them
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/alacritty alacritty
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR starship
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $HOME bashrc

# Restore the configuration files from the dotfiles repository
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/alacritty alacritty
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR starship --ignore=themes/*
stow --dotfiles $STOW_V $STOW_N -d $DOTFILES_DIR -t ~ bashrc

#Install starship prompt
if [ "$DRY_RUN" -eq 0 ]; then
    run curl -sS https://starship.rs/install.sh | sh
fi

log "Dotfiles restored successfully"

# Install microsoft-edge-stable-bin from AUR and configure as default browser
# Commented out becuase pacman does not have edge. Prob have to use yay instead.
# sudo pacman -S microsoft-edge-stable-bin
# xdg-settings set default-web-browser microsoft-edge-stable-bin.desktop