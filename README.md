## Customized Omarchy Dotfiles

This repository contains dotfiles for a customized Omarchy installation. It is intended to be used with GNU Stow to symlink configuration files into place under `~/.config` and your home directory.

### Requirements
- Omarchy installed and configured on your system
- GNU Stow (`stow`)

## Quick start
Clone into your home directory so it lives at `~/.dotfiles`:

```bash
git clone git@github.com:yourname/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Use the included stow-restore script
This script backs up any existing configs, removes previous Stow links for these targets, and then stows this repo.

```bash
chmod +x ./stow-restore.sh
./stow-restore.sh
```

What it does:
- Backs up `~/.config/hypr`, `~/.config/waybar`, `~/.config/bash` into `~/.config/_config_backup/`
- Backs up your `~/.bashrc` to `~/._config_backup/bashrc.backup`
- Unstows previous links for these targets
- Stows the contents of this repository into place

Tip: Use `stow -n` for a dry run if you want to preview changes, or edit the backup paths in the script to suit your preferences.

### Manual alternative (optional)
If you prefer to stow by hand:

```bash
mkdir -p ~/.config/{hypr,waybar,bash}
stow -v -d ~/.dotfiles -t ~/.config hypr waybar bash
stow --dotfiles -v -d ~/.dotfiles -t ~ bashrc
```


## SSH agent helper
The provided Bash `ssh-agent.sh` sets up a persistent SSH agent at `~/.config/ssh-agent.sock` and auto‑adds keys. The included `bashrc/.bashrc` already sources it:

```bash
source "$HOME/.config/bash/ssh-agent.sh"
```

To verify:

```bash
echo "$SSH_AUTH_SOCK"
ssh-add -l
```

## Cursor dev launcher
`hypr/scripts/cursor-dev-launcher` opens a simple picker (via `walker`) to select a project and launch it in Cursor (via `uwsm`). Configure search roots inside the script:

```bash
BASE_DIRS=(
  "$HOME/Documents/dev"
)
PROJECTS=(
  "Custom Dotfiles|$HOME/.dotfiles"
)
```
This is bound in Hyprland via `hypr/bindings.conf` as `SUPER+SHIFT+ALT+C` ("Cursor Dev").



