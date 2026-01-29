#!/bin/bash
# Restore the most recent backup from ~/.config_backups back into ~/.config and $HOME
# Matches the structure created by stow-restore.sh
#
# Usage:
#   restore-backup.sh [-v] [-n]
#     -v  verbose
#     -n  dry run
#

set -euo pipefail

CONFIG_DIR="$HOME/.config"
BACKUPS_ROOT="$HOME/.config_backups"
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
  exit "\${1:-0}"
}

while getopts ":hvn" opt; do
  case "$opt" in
    h) usage 0 ;;
    v) VERBOSE=1 ;;
    n) DRY_RUN=1 ;;
    \?) echo "Unknown option: -$OPTARG" >&2; usage 2 ;;
  esac
done
shift $((OPTIND - 1))

run() { if [ "$DRY_RUN" -eq 1 ]; then echo "+ $*"; else "$@"; fi; }
log() { [ "$VERBOSE" -eq 1 ] && echo "$*"; }

if [ ! -d "$BACKUPS_ROOT" ]; then
  echo "No backups root found at $BACKUPS_ROOT" >&2
  exit 1
fi

# Pick most recent backup directory (timestamped YYYYmmdd_HHMMSS)
LATEST_BACKUP="$(ls -1dt "$BACKUPS_ROOT"/* 2>/dev/null | head -n 1 || true)"
if [ -z "$LATEST_BACKUP" ] || [ ! -d "$LATEST_BACKUP" ]; then
  echo "No backups found in $BACKUPS_ROOT" >&2
  exit 1
fi

echo "Restoring from backup: $LATEST_BACKUP"

# Ensure base config directory exists
run mkdir -p "$CONFIG_DIR"

# Restore directories
restore_dir() {
  local name="$1"
  local src="$LATEST_BACKUP/$name"
  local dst="$CONFIG_DIR/$name"
  if [ -d "$src" ]; then
    log "Restoring directory $name"
    run rm -rf "$dst"
    run cp -a "$src" "$dst"
  else
    log "Skipping $name (not present in backup)"
  fi
}

# Restore files (in ~/.config)
restore_config_file() {
  local name="$1"
  local src="$LATEST_BACKUP/$name"
  local dst="$CONFIG_DIR/$name"
  if [ -e "$src" ]; then
    log "Restoring file $name"
    run rm -f "$dst"
    run cp -a "$src" "$dst"
  else
    log "Skipping $name (not present in backup)"
  fi
}

# Restore $HOME files
restore_home_file() {
  local name="$1"
  local src="$LATEST_BACKUP/$name"
  local dst="$HOME/$name"
  if [ -e "$src" ]; then
    log "Restoring home file $name"
    run rm -f "$dst"
    run cp -a "$src" "$dst"
  else
    log "Skipping $name (not present in backup)"
  fi
}

# Directories captured by stow-restore backups
restore_dir "alacritty"
restore_dir "bash"
restore_dir "hypr"
restore_dir "waybar"
restore_dir "omarchy"
restore_dir "systemd"

# Files captured by stow-restore backups
restore_config_file "starship.toml"

# Home dotfiles captured by stow-restore backups
restore_home_file ".bashrc"

# If systemd user units were restored, reload and ensure timer is active
if [ -d "$CONFIG_DIR/systemd/user" ]; then
  log "Reloading systemd user daemon"
  run systemctl --user daemon-reload
  if [ -f "$CONFIG_DIR/systemd/user/omarchy-bg-next.timer" ]; then
    log "Enabling and restarting omarchy-bg-next.timer"
    run systemctl --user enable --now omarchy-bg-next.timer
    run systemctl --user restart omarchy-bg-next.timer
  fi
fi

echo "Restore complete."




