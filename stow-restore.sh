#!/bin/bash
# This script restores the configuration files from the dotfiles repository to the ~/.config directory.
# If new folders are added to the dotfiles repository, they should be added to this script.
# It also backs up the existing configuration files to the ~/.config directory.

DOTFILES_DIR=~/.dotfiles
CONFIG_DIR=~/.config
BACKUPS_ROOT=$HOME/.config_backups
BACKUP_DIR=$BACKUPS_ROOT/$(date +%Y%m%d_%H%M%S)

# Flags (defaults)
VERBOSE=0
DRY_RUN=0
RESTORE_MODE=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -h        Show this help and exit
  -v        Verbose output
  -n        Dry run (print commands instead of executing)
  -r        Restore most recent backup and exit
EOF
  exit "${1:-0}"
}

# Parse short options
while getopts ":hvnr" opt; do
  case "$opt" in
    h) usage 0 ;;
    v) VERBOSE=1 ;;
    n) DRY_RUN=1 ;;
    r) RESTORE_MODE=1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage 2 ;;
  esac
done
shift $((OPTIND - 1))

# Helpers
run() { if [ "$DRY_RUN" -eq 1 ]; then echo "+ $*"; else "$@"; fi; }
log() { if [ "$VERBOSE" -eq 1 ]; then echo "$*"; fi; }

STOW_N=$([ "$DRY_RUN" -eq 1 ] && echo "-n")
STOW_V=$([ "$VERBOSE" -eq 1 ] && echo "-v")

# If -r was provided, run the backup restore helper and exit
if [ "$RESTORE_MODE" -eq 1 ]; then
  RESTORE_FLAGS=""
  [ "$VERBOSE" -eq 1 ] && RESTORE_FLAGS="$RESTORE_FLAGS -v"
  [ "$DRY_RUN" -eq 1 ] && RESTORE_FLAGS="$RESTORE_FLAGS -n"
  run "$DOTFILES_DIR/restore-backup.sh" $RESTORE_FLAGS
  exit $?
fi


# Create the backups root and a timestamped backup directory
run mkdir -p $BACKUPS_ROOT
run mkdir -p $BACKUP_DIR

# Backup the existing configuration files
run mv $CONFIG_DIR/alacritty $BACKUP_DIR/alacritty
run mv $CONFIG_DIR/bash $BACKUP_DIR/bash
run mv $CONFIG_DIR/hypr $BACKUP_DIR/hypr
run mv $CONFIG_DIR/waybar $BACKUP_DIR/waybar
run mv $CONFIG_DIR/sunshine $BACKUP_DIR/sunshine
run mv $CONFIG_DIR/starship.toml $BACKUP_DIR/starship.toml
run mv $HOME/.bashrc $BACKUP_DIR/.bashrc

# Backup the omarchy, systemd, and microsoft-edge directories (copy instead of move)
run cp -r $CONFIG_DIR/omarchy $BACKUP_DIR/omarchy
run cp -r $CONFIG_DIR/systemd $BACKUP_DIR/systemd

# Create the configuration file directories if they don't exist
run mkdir -p $CONFIG_DIR/alacritty
run mkdir -p $CONFIG_DIR/bash
run mkdir -p $CONFIG_DIR/hypr
run mkdir -p $CONFIG_DIR/waybar
run mkdir -p $CONFIG_DIR/sunshine
run mkdir -p $CONFIG_DIR/omarchy
run mkdir -p $CONFIG_DIR/systemd

# Undo linking all of the dotfiles before restoring them
echo "Unlinking old dotfiles..."
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/alacritty alacritty
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/sunshine sunshine
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR starship
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR omarchy
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/systemd systemd
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $HOME bashrc

# Restore the configuration files from the dotfiles repository
echo "Linking new dotfiles..."
echo "Linking alacritty"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/alacritty alacritty
echo "Linking bash"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
echo "Linking hypr"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
echo "Linking waybar"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
log "Restoring sunshine"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/sunshine sunshine
echo "Linking starship"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR starship --ignore=themes/*
echo "Linking bashrc"
stow --dotfiles $STOW_V $STOW_N -d $DOTFILES_DIR -t ~ bashrc

# Set up theme
echo "Restoring custom themes..."
run rsync -a $STOW_V $STOW_N --progress ~/.dotfiles/omarchy/themes ~/.config/omarchy --exclude=**/.git
omarchy-theme-set synthwave84

# Stow the systemd user service files. mkdir of the user/ directory prevents
# stow from tree-folding the whole user/ directory into a single symlink. Stow
# will refuse to overwrite any non-symlink file, so existing contents of
# ~/.config/systemd/user/ are left untouched.
log "Restoring systemd user services"
run mkdir -p $CONFIG_DIR/systemd/user
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/systemd systemd
run systemctl --user daemon-reload

# Seed HubApps file for Microsoft Edge (only if it doesn't exist, so as not to overwrite modified settings)
log "Seeding HubApps file for Microsoft Edge"
if [ ! -f $CONFIG_DIR/microsoft-edge/Default/HubApps ]; then
  run cp -r $DOTFILES_DIR/microsoft-edge/Default/HubApps $CONFIG_DIR/microsoft-edge/Default/HubApps
fi

echo "Dotfiles restored successfully"