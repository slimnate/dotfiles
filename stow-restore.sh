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
log() { [ "$VERBOSE" -eq 1 ] && echo "$*"; }

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
run mkdir -p $CONFIG_DIR/omarchy
run mkdir -p $CONFIG_DIR/systemd

# Undo linking all of the dotfiles before restoring them
log "Undoing linking all of the dotfiles before restoring them"
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/alacritty alacritty
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR starship
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR omarchy
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR systemd
stow --D $STOW_V $STOW_N -d $DOTFILES_DIR -t $HOME bashrc

# Restore the configuration files from the dotfiles repository
log "Restoring the configuration files from the dotfiles repository"
log "Restoring alacritty"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/alacritty alacritty
log "Restoring bash"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/bash bash
log "Restoring hypr"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/hypr hypr
log "Restoring waybar"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR/waybar waybar
log "Restoring starship"
stow $STOW_V $STOW_N -d $DOTFILES_DIR -t $CONFIG_DIR starship --ignore=themes/*
log "Restoring bashrc"
stow --dotfiles $STOW_V $STOW_N -d $DOTFILES_DIR -t ~ bashrc

# Set up theme
echo "Restoring custom themes..."
run rsync -a $STOW_V $STOW_N --progress ~/.dotfiles/omarchy/themes ~/.config/omarchy --exclude=**/.git
omarchy-theme-set synthwave84

# log "Copying systemd files"
# run rm -rf ~/.config/systemd/user/omarchy-bg-next.service
# run rm -rf ~/.config/systemd/user/omarchy-bg-next.timer
# # run rsync -a $STOW_V $STOW_N --progress ~/.dotfiles/systemd/user ~/.config/systemd

# # Reload user daemon and enable timer for Omarchy background rotation
# run systemctl --user daemon-reload
# run systemctl --user enable --now omarchy-bg-next.timer
# run systemctl --user start omarchy-bg-next.service || true
# log "Omarchy background timer enabled. View logs with: journalctl --user -u omarchy-bg-next.service -e"

# Seed HubApps file for Microsoft Edge (only if it doesn't exist, so as not to overwrite modified settings)
log "Seeding HubApps file for Microsoft Edge"
if [ ! -f $CONFIG_DIR/microsoft-edge/Default/HubApps ]; then
  run cp -r $DOTFILES_DIR/microsoft-edge/Default/HubApps $CONFIG_DIR/microsoft-edge/Default/HubApps
fi

log "Dotfiles restored successfully"