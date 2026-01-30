# Customized Omarchy Dotfiles

This repository contains dotfiles for a customized Omarchy installation. It is intended to be used with [GNU Stow](https://www.gnu.org/software/stow/) to symlink configuration files into place under `~/.config` and your home directory.

### Requirements
- [Omarchy](https://omarchy.org/) installed and configured on your system
- GNU Stow (`stow`)

## Quick start
Clone into your home directory so it lives at `~/.dotfiles`:

```bash
git clone git@github.com:yourname/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Install dependencies
Run the `install-deps.sh` script to install dependencies not included in Omarchy.

```bash
chmod +x ./install-deps.sh
./install-deps.sh
```

Required deps installed:
- [GNU Stow](https://www.gnu.org/software/stow/) for stowing
- [rsync](https://wiki.archlinux.org/title/Rsync) for managing backup files

Optional deps that will be prompted before installing
- Microsoft Edge (set as default browser with this script as well)
- [Starship](https://starship.rs/) terminal prompt
- [Joplin](https://joplinapp.org/) notes
- [polychromatic](https://aur.archlinux.org/packages/polychromatic) for razer devices

### Run stow restore
This script backs up any existing configs, removes previous Stow links for these targets, and then stows this repo.

```bash
chmod +x ./stow-restore.sh
./stow-restore.sh
```

#### What it does:
- Backs up any existing config files that will be overwritten to `~/.config_backup/`. All backups are stored relative to `~/`
- Unstows previous links for these targets
- Stows the contents of this repository to create symlinks to this repo

#### CLI Options
The following options can be used when running `stow-restore.sh`:

| flag | Description |
|------|-------------|
| -h   | Show help documentation for the script. |
| -v   | Verbose output of what the script is doing. |
| -n   | Dry run. Does nt modify any files, just prints a list of commands to be executed. This command still runs the `stow` command wiht the -n flag so that you can see all changes that stow wants to make as well. |

## Overview of customizations

### Alacritty
No customizations for now, but the config si stowed so I can make changes later.

### Bash
Customizations to `.bashrc`

#### SSH agent helper
The provided Bash `ssh-agent.sh` sets up a persistent SSH agent at `~/.config/ssh-agent.sock` and auto‑adds keys. The included `bashrc/.bashrc` already sources it:

```bash
source "$HOME/.config/bash/ssh-agent.sh"
```

To verify:

```bash
echo "$SSH_AUTH_SOCK"
ssh-add -l
```

### Hypr
- `hypr/autostart.conf` - Sets up window rules for how I like to configure my virtual desktops. Launches cursor, edge, Joplin, and spotify
- `hypr/bindings.conf` - Set up custom keybindings (see [Keybindings](#keybindings) below)
- `hypr/envs.conf` - Extra environment variables - currently empty
- `hypr/hypridle.conf` - hypridle config
- `hypr/hyprland.conf` - Base hyprland conf; sources all the other files in this directory
- `hypr/hyprlock.conf` - Lock screen config
- `hypr/hyprsunset.conf` - Omarchy default - disables hyprsunset
- `hypr/input.conf` - Input config. Custom mouse acceleration profile
- `hypr/looknfeel.conf` - Look and feel config
- `hypr/monitors.conf` - Monitor config

#### Keybindings
| Keybinding | Action | Description |
|------------|--------|-------------|
| **System** |
| `SUPER + R` | Reload Hyprland | Reloads Hyprland configuration |
| **Code Editor (Cursor)** |
| `SUPER + SHIFT + C` | Code Editor (Cursor) | Launches Cursor code editor |
| `SUPER + SHIFT + ALT + SPACE` | Projects (Cursor) | Launches Cursor dev launcher script |
| **AI Services** |
| `SUPER + SHIFT + A` | Grok | Opens Grok webapp (https://grok.com) |
| `SUPER + SHIFT + ALT + A` | ChatGPT | Opens ChatGPT webapp (https://chatgpt.com) |
| **Git Tools** |
| `SUPER + SHIFT + L` | Lazygit | Opens Lazygit terminal UI in terminal |
| `SUPER + SHIFT + G` | GitHub | Opens GitHub webapp (https://github.com/) |
| **Workspace Notifications** |
| `SUPER + 1` | Workspace Notification | Shows "CODE" notification when switching to workspace 1 |
| `SUPER + 2` | Workspace Notification | Shows "BROWSER" notification when switching to workspace 2 |
| `SUPER + 3` | Workspace Notification | Shows "LAZYGIT" notification when switching to workspace 3 |
| `SUPER + 8` | Workspace Notification | Shows "NOTES" notification when switching to workspace 8 |
| `SUPER + 9` | Workspace Notification | Shows "SPOTIFY" notification when switching to workspace 9 |
| **Monitor Management** |
| `SUPER + SHIFT + ALT + LEFT` | Move Workspace Left | Moves current workspace to monitor 0 (left monitor) |
| `SUPER + SHIFT + ALT + RIGHT` | Move Workspace Right | Moves current workspace to monitor 1 (right monitor) |

### Starship
Starship prompt config. Custom themes in the `themes` dir. Just copy the contents of a theme into `starship.toml` to apply it.

### Waybar
Custom configuration for waybar.

### Microsoft Edge `HubApps` to enable sidebar/copilot mode
If the `~/.config/microsoft-edge/Default/HubApps` file does not exist, the `stow-restore.sh` script will seed one to enable sidebar and Copilot mode support. **This will require a restart of Edge.**

##### About the HubApps file
This file is a required configuration file for Microsoft Edge Sidebar to work, but is not included in the edge installer. It was taken from: [`https://github.com/RPDJF/dotfiles/blob/master/.myconfig/ressources/HubApps`](https://github.com/RPDJF/dotfiles/blob/master/.myconfig/ressources/HubApps)

See the following resources for more info:
[https://github.com/MicrosoftEdge/DevTools/issues/278](https://github.com/MicrosoftEdge/DevTools/issues/278)
[https://dev.to/0xtanzim/how-to-fix-the-copilot-sidebar-in-microsoft-edge-on-linux-efd](https://dev.to/0xtanzim/how-to-fix-the-copilot-sidebar-in-microsoft-edge-on-linux-efd)

### Project Launcher
`hypr/scripts/cursor-dev-launcher` opens a simple picker (via `walker`) to select a project and launch it in Cursor (via `uwsm`). Bound to `SUPER+SHIFT+ALT+Space`

Configure search roots inside the script:

```bash
BASE_DIRS=(
  "$HOME/Documents/dev"
)
PROJECTS=(
  "Custom Dotfiles|$HOME/.dotfiles"
)
```