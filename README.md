# Customized Omarchy Dotfiles

This repository contains dotfiles for a customized Omarchy installation. It is intended to be used with [GNU Stow](https://www.gnu.org/software/stow/) to symlink configuration files into place under `~/.config` and your home directory.

### Requirements
- [Omarchy](https://omarchy.org/) installed and configured on your system
- GNU Stow (`stow`)
- [`yay`](https://github.com/Jguer/yay) (AUR helper) for optional AUR packages in `install-deps.sh`

## Quick start
Clone into your home directory so it lives at `~/.dotfiles`:

```bash
git clone git@github.com:<yourname>/dotfiles.git ~/.dotfiles
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

Optional deps that will be prompted before installing:
- [Joplin](https://joplinapp.org/) notes (`yay` required to install from AUR)
- [Starship](https://starship.rs/) terminal prompt
- [asciiquarium](https://github.com/cmatsuoka/asciiquarium) (terminal screensaver; bound to `SUPER+SHIFT+I`)
- Microsoft Edge (AUR via `yay`; set as default browser with this script as well)
- [polychromatic](https://aur.archlinux.org/packages/polychromatic) for Razer devices (`yay`)

### Run stow restore
This script backs up any existing configs, removes previous Stow links for these targets, and then stows this repo.

```bash
chmod +x ./stow-restore.sh
./stow-restore.sh
```

#### What it does:
- Backs up existing configs that will be overwritten to `~/.config_backups/` (timestamped). Backups are stored relative to `~/`
- Unstows previous links for these targets
- Stows packages into place: `alacritty`, `bash`, `hypr`, `waybar`, `starship`, `omarchy`, `systemd`, and `bashrc` → `~/.bashrc`
- Syncs `omarchy/themes` into `~/.config/omarchy` and runs `omarchy-theme-set synthwave84`
- Seeds Microsoft Edge `HubApps` if missing (see below)

To restore the most recent backup instead of stowing:

```bash
./stow-restore.sh -r
```

This delegates to `restore-backup.sh`.

#### CLI Options
The following options can be used when running `stow-restore.sh`:

| flag | Description |
|------|-------------|
| -h   | Show help documentation for the script. |
| -v   | Verbose output of what the script is doing. |
| -n   | Dry run. Does not modify any files, just prints a list of commands to be executed. This still runs `stow` with `-n` so you can see all changes stow would make. |
| -r   | Restore the most recent backup via `restore-backup.sh` and exit. |

## Overview of customizations

### Alacritty
Stowed terminal config with Omarchy theme import, CaskaydiaMono Nerd Font at size 9, window padding, undecorated window, and keybindings for F11 fullscreen plus Shift/Ctrl+Insert paste/copy.

### Bash
Customizations to `.bashrc` (stowed from `bashrc/.bashrc`):

- Prepends `~/.local/bin` to `PATH`
- Sources `~/.local/bin/env` when present
- Sources the SSH agent helper
- Initializes Starship

#### SSH agent helper
The provided Bash `ssh-agent.sh` (stowed to `~/.config/bash/`) sets up a persistent SSH agent at `~/.config/ssh-agent.sock` and auto-adds keys. `.bashrc` already sources it:

```bash
source "$HOME/.config/bash/ssh-agent.sh"
```

To verify:

```bash
echo "$SSH_AUTH_SOCK"
ssh-add -l
```

### Hypr
- `hypr/autostart.conf` - Workspace window rules and autostart: Cursor, Edge, lazygit, Joplin, and Spotify
- `hypr/bindings.conf` - Custom keybinding overrides (see [Keybindings](#keybindings) below)
- `hypr/envs.conf` - Extra env file (no active `env =` lines); NVIDIA envs are set in `hyprland.conf`, and `GDK_SCALE` is in `monitors.conf`
- `hypr/hypridle.conf` - Shared hypridle config; sources the active idle profile
- `hypr/hypridle.profile.conf` - Switches between laptop/desktop hypridle overrides
- `hypr/hypridle.laptop.conf` / `hypr/hypridle.desktop.conf` - Host-specific idle overrides
- `hypr/hyprland.conf` - Base hyprland conf; sources Omarchy defaults plus the files in this directory; also sets NVIDIA env vars
- `hypr/hyprlock.conf` - Lock screen config
- `hypr/hyprsunset.conf` - Omarchy default - disables hyprsunset
- `hypr/input.conf` - Shared input config (mouse accel, touchpad, etc.); sources the active input profile
- `hypr/input.profile.conf` - Switches between laptop/desktop input overrides
- `hypr/input.laptop.conf` / `hypr/input.desktop.conf` - Host-specific input overrides
- `hypr/looknfeel.conf` - Look and feel config
- `hypr/monitors.conf` - Monitor config (includes `GDK_SCALE`)
- `hypr/windows.conf` - Window opacity rules (global translucency; full opacity for Edge, Spotify, and Joplin)
- `hypr/scripts/cursor-dev-launcher` - Project picker for Cursor (see [Project Launcher](#project-launcher))

#### Laptop / desktop profiles
Shared Hyprland and hypridle settings live in `input.conf` and `hypridle.conf`. Host-specific tweaks are kept in small profile files so the same repo works on both machines.

**How it works**
1. `input.conf` sources `~/.config/hypr/input.profile.conf`
2. `hypridle.conf` sources `~/.config/hypr/hypridle.profile.conf`
3. Each `*.profile.conf` sources exactly one of `*.laptop.conf` or `*.desktop.conf`

**How to switch**
Edit both profile switchers and leave only one `source` line active in each:

```conf
# hypr/input.profile.conf
source = ~/.config/hypr/input.laptop.conf
# source = ~/.config/hypr/input.desktop.conf
```

```conf
# hypr/hypridle.profile.conf
source = ~/.config/hypr/hypridle.laptop.conf
# source = ~/.config/hypr/hypridle.desktop.conf
```

Then reload:

```bash
hyprctl reload
# restart hypridle if idle settings should apply immediately
systemctl --user restart hypridle.service
```

Keep laptop/desktop selection in sync across both profile files.

**Differences**

| Setting | Laptop | Desktop |
|---------|--------|---------|
| Pointer `sensitivity` (`input.*.conf`) | `0.05` (slightly faster trackpad/pointer feel) | `-0.5` (slower / less twitchy for desk mouse) |
| `inhibit_sleep` (`hypridle.*.conf`) | `1` (normal idle inhibit) | `3` (wait until the screen is locked before sleep) |

Shared input settings that apply on both hosts (accel profile, touchpad scroll factor, Razer Basilisk device curve, etc.) stay in `input.conf`. Put new machine-specific overrides in the matching `*.laptop.conf` / `*.desktop.conf` files instead of forking the shared configs.

#### Keybindings
Custom overrides only (Omarchy defaults still apply unless unbound/replaced in `bindings.conf`):

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
| **Fun** |
| `SUPER + SHIFT + I` | Asciiquarium | Opens fullscreen asciiquarium in Alacritty |

### Starship
Live prompt config is `starship/starship.toml` (stowed to `~/.config/starship.toml`). Extra theme samples live under `starship/themes/` and are kept in the repo only (`stow` ignores that directory). To try one, copy its contents into `starship.toml`.

### Waybar
Custom bar layout and styling: workspace icons, MPRIS now-playing, Omarchy modules (menu/update/screenrecording), and CSS that imports the active Omarchy theme (`../omarchy/current/theme/waybar.css`).

### Omarchy themes
Custom themes under `omarchy/themes/` (`pulsar`, `synthwave84`). `stow-restore.sh` syncs them into `~/.config/omarchy` and applies `synthwave84`.

### systemd
User units in `systemd/user/`:
- `omarchy-bg-next.service` / `omarchy-bg-next.timer` — rotate Omarchy backgrounds

These are stowed with the rest of the config. The enable/start steps in `stow-restore.sh` are currently commented out; enable manually if you want the timer.

### Sunshine
Configuration for [Sunshine](https://github.com/LizardByte/Sunshine) game/desktop streaming.

- `sunshine/sunshine.conf` - main Sunshine config (capture backend, NVENC encoder, log level, etc.)
- `sunshine/apps.json` - defines a `Desktop` app whose `prep-cmd` hooks start/stop a headless Hyprland output for streaming:
  - `hypr/scripts/sunshine-session-start` - runs when a Sunshine client connects
  - `hypr/scripts/sunshine-session-stop` - runs when the client disconnects

Both files are stowed into `~/.config/sunshine/`.

#### Systemd service drop-in
`systemd/user/sunshine.service.d/override.conf` adds `After=graphical-session.target` and `PartOf=graphical-session.target` so the `sunshine.service` user unit starts after the graphical session is ready and stops with it.

`stow-restore.sh` stows the `systemd` package into `~/.config/systemd/`, which links everything under `systemd/user/` (including `sunshine.service.d/override.conf`) into `~/.config/systemd/user/`. Stow refuses to overwrite non-symlinks, so any existing files already in `~/.config/systemd/user/` are left untouched and will surface as conflicts rather than being clobbered. After linking, the script runs `systemctl --user daemon-reload` so new/updated units are picked up immediately.

### Microsoft Edge `HubApps` to enable sidebar/copilot mode
If the `~/.config/microsoft-edge/Default/HubApps` file does not exist, the `stow-restore.sh` script will seed one to enable sidebar and Copilot mode support. **This will require a restart of Edge.**

##### About the HubApps file
This file is a required configuration file for Microsoft Edge Sidebar to work, but is not included in the edge installer. It was taken from: [`https://github.com/RPDJF/dotfiles/blob/master/.myconfig/ressources/HubApps`](https://github.com/RPDJF/dotfiles/blob/master/.myconfig/ressources/HubApps)

See the following resources for more info:
[https://github.com/MicrosoftEdge/DevTools/issues/278](https://github.com/MicrosoftEdge/DevTools/issues/278)
[https://dev.to/0xtanzim/how-to-fix-the-copilot-sidebar-in-microsoft-edge-on-linux-efd](https://dev.to/0xtanzim/how-to-fix-the-copilot-sidebar-in-microsoft-edge-on-linux-efd)

### Project Launcher
`hypr/scripts/cursor-dev-launcher` opens a simple picker (via `walker`) to select a project and launch it in Cursor (via `uwsm-app`). Bound to `SUPER+SHIFT+ALT+Space`

Configure search roots inside the script:

```bash
BASE_DIRS=(
  "$HOME/Documents/dev"
)
PROJECTS=(
  "Custom Dotfiles|$HOME/.dotfiles"
  "Omarchy Config|$HOME/.local/share/omarchy"
  "OpenClaw Config|$HOME/.openclaw"
)
```
