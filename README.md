# Customized Omarchy Dotfiles

This repository contains dotfiles for a customized [Omarchy](https://omarchy.org/) installation (Quattro / Omarchy 4). It is intended to be used with [GNU Stow](https://www.gnu.org/software/stow/) to symlink configuration files into place under `~/.config` and your home directory.

### Requirements
- Omarchy 4 (Quattro) installed and configured
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
- Backs up existing configs that will be overwritten to `~/.config_backups/` (timestamped)
- Unstows previous links for these targets
- Stows packages: `alacritty`, `bash`, `hypr`, `starship`, `omarchy`, `systemd`, and `bashrc` → `~/.bashrc`
- Syncs `omarchy/themes` into `~/.config/omarchy` and runs `omarchy theme set synthwave84`
- Seeds Microsoft Edge `HubApps` if missing (see below)

To restore the most recent backup instead of stowing:

```bash
./stow-restore.sh -r
```

This delegates to `restore-backup.sh`.

#### CLI Options

| flag | Description |
|------|-------------|
| -h   | Show help documentation for the script. |
| -v   | Verbose output of what the script is doing. |
| -n   | Dry run. Does not modify any files, just prints a list of commands to be executed. This still runs `stow` with `-n` so you can see all changes stow would make. |
| -r   | Restore the most recent backup via `restore-backup.sh` and exit. |

## Overview of customizations

### Alacritty
Stowed terminal config with Quattro theme import from `~/.local/state/omarchy/current/theme/alacritty.toml`, CaskaydiaMono Nerd Font at size 9, window padding, undecorated window, F11 fullscreen, Shift/Ctrl+Insert paste/copy, and CSI-u Shift+Return / Alt+Shift+Return bindings for tmux and TUIs.

### Bash
Customizations to `.bashrc` (stowed from `bashrc/.bashrc`):

- Sets `OMARCHY_PATH` to `/usr/share/omarchy` (Quattro package path)
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

### Hyprland (Lua)
Omarchy Quattro loads Hyprland via Lua. Custom files under `hypr/`:

| File | Role |
|------|------|
| `hyprland.lua` | Entry require list (includes `hypr.windows` and `hypr.machine`) |
| `monitors.lua` | Display modes, positions, `GDK_SCALE` |
| `input.lua` | Shared input (accel, touchpad, Razer Basilisk curve) |
| `machine.lua` | Laptop vs desktop pointer sensitivity via `omarchy-hw-laptop` |
| `bindings.lua` | Personal keybinding overrides |
| `looknfeel.lua` | Look and feel |
| `windows.lua` | Workspace placement, opacity opt-outs, persistent workspaces |
| `autostart.lua` | `exec-once` apps |
| `hyprsunset.conf` | Still hyprlang (read by hyprsunset) |
| `xdph.conf` | XDG desktop portal Hyprland |
| `scripts/cursor-dev-launcher` | Project picker for Cursor |

Idle timing and lock live in `omarchy/shell.json` (`idle.screensaver` / `idle.lock`), not hypridle/hyprlock.

#### Machine detection
`machine.lua` uses `o.shell_succeeds("omarchy-hw-laptop")` so the same repo works on laptop and desktop without editing profile switchers. Pointer sensitivity is `0.05` on laptop and `-0.5` on desktop.

#### Keybindings
Custom overrides only (Omarchy defaults still apply unless unbound/replaced in `bindings.lua`):

| Keybinding | Action |
|------------|--------|
| `SUPER + SHIFT + C` | Cursor |
| `SUPER + SHIFT + ALT + SPACE` | Cursor project launcher |
| `SUPER + SHIFT + A` | Grok |
| `SUPER + SHIFT + ALT + A` | ChatGPT |
| `SUPER + SHIFT + L` | Lazygit |
| `SUPER + SHIFT + G` | GitHub |
| `SUPER + 1` / `2` / `3` / `8` / `9` | Workspace switch + label toast |
| `SUPER + SHIFT + I` | Asciiquarium |

### Shell / bar
Bar layout, idle, and widgets are configured in `omarchy/shell.json` (Quickshell / `omarchy-shell`):

- Left: menu, `slim.workspaces` (persistent 1–9 with icons), media
- Center: indicators, active window, clock, keyboard layout, weather, system update
- Right: tray, tailscale, agents, bluetooth, network, audio, `slim.cpu` / `slim.memory` / `slim.disk`, monitor, power

Custom plugins live under `omarchy/plugins/` (`slim.workspaces`, `slim.cpu`, `slim.memory`, `slim.disk`). Stats use `omarchy/bar/scripts/system-stats`.

### Starship
Live prompt config is `starship/starship.toml` (stowed to `~/.config/starship.toml`). Extra theme samples live under `starship/themes/` and are kept in the repo only (`stow` ignores that directory). To try one, copy its contents into `starship.toml`.

### Omarchy themes
Custom Quattro theme under `omarchy/themes/synthwave84` (`colors.toml` + `backgrounds/`). `stow-restore.sh` syncs themes into `~/.config/omarchy` and applies with:

```bash
omarchy theme set synthwave84
```

### systemd
User units in `systemd/user/`:

- `omarchy-bg-next.service` / `omarchy-bg-next.timer` — rotate Omarchy backgrounds every 5 minutes (`PATH` includes `/usr/share/omarchy/bin`)

These are stowed with the rest of the config. `stow-restore.sh` reloads the user
daemon, enables the timer, and runs one cycle so the next rotation is scheduled.

Check status:

```bash
systemctl --user list-timers omarchy-bg-next.timer
journalctl --user -u omarchy-bg-next.service -e
```

### Microsoft Edge `HubApps` to enable sidebar/copilot mode
If the `~/.config/microsoft-edge/Default/HubApps` file does not exist, the `stow-restore.sh` script will seed one to enable sidebar and Copilot mode support. **This will require a restart of Edge.**

##### About the HubApps file
This file is a required configuration file for Microsoft Edge Sidebar to work, but is not included in the edge installer. It was taken from: [`https://github.com/RPDJF/dotfiles/blob/master/.myconfig/ressources/HubApps`](https://github.com/RPDJF/dotfiles/blob/master/.myconfig/ressources/HubApps)

See the following resources for more info:
[https://github.com/MicrosoftEdge/DevTools/issues/278](https://github.com/MicrosoftEdge/DevTools/issues/278)
[https://dev.to/0xtanzim/how-to-fix-the-copilot-sidebar-in-microsoft-edge-on-linux-efd](https://dev.to/0xtanzim/how-to-fix-the-copilot-sidebar-in-microsoft-edge-on-linux-efd)

### Project Launcher
`hypr/scripts/cursor-dev-launcher` opens a simple picker (via `walker`) to select a project and launch it in Cursor (via `uwsm-app`). Bound to `SUPER+SHIFT+ALT+Space`.

Configure search roots inside the script:

```bash
BASE_DIRS=(
  "$HOME/Documents/dev"
)
PROJECTS=(
  "Custom Dotfiles|$HOME/.dotfiles"
  "Omarchy Config|/usr/share/omarchy"
  "OpenClaw Config|$HOME/.openclaw"
)
```
