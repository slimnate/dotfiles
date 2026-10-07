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
- Microsoft Edge (AUR via `yay`; set as the Omarchy/XDG default with `omarchy default browser edge`)
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
- Stows packages: `alacritty`, `bash`, `hypr`, `starship`, `omarchy`, `systemd`, `cursor` → `~/.config/Cursor/User/keybindings.json`, `bashrc` → `~/.bashrc`, and `bin` → `~/.local/bin`
- Syncs `omarchy/themes` into `~/.config/omarchy` and runs `omarchy theme set synthwave84`
- Seeds Microsoft Edge `HubApps` if missing (see below)
- Sets Microsoft Edge as the Omarchy/XDG default browser when `microsoft-edge-stable` is installed
- Clones missing third-party plugins from `plugin-sources.json` via `install-plugins.sh` (forwards `-n` / `-v`)

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

### Install third-party plugins
Custom `slim.*` plugins are vendored under `omarchy/plugins/` and stowed with the rest of the config. Third-party plugins are git clones; their URLs live in `plugin-sources.json`. Enablement and bar placement stay in `omarchy/shell.json` (`install-plugins.sh` does not pass `--enable`).

`stow-restore.sh` runs `install-plugins.sh` at the end (already-installed ids are skipped). You can still run it on its own:

```bash
chmod +x ./install-plugins.sh
./install-plugins.sh
```

To refresh the lockfile from plugins currently installed on this machine:

```bash
chmod +x ./dump-plugins.sh
./dump-plugins.sh
```

`dump-plugins.sh -n` prints the JSON without writing. Day-to-day updates of already-cloned plugins remain `omarchy plugin update`.

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

Idle timing and lock live in `omarchy/shell.json` (`idle.screensaver` / `idle.lock`), not hypridle/hyprlock.

#### Machine detection
`machine.lua` uses `o.shell_succeeds("omarchy-hw-laptop")` so the same repo works on laptop and desktop without editing profile switchers. Pointer sensitivity is `0.05` on laptop and `-0.5` on desktop.

#### Keybindings
Custom overrides only (Omarchy defaults still apply unless unbound/replaced in `bindings.lua`):

| Keybinding | Action |
|------------|--------|
| `SUPER + SHIFT + C` | Cursor |
| `SUPER + SHIFT + ALT + SPACE` | Project launcher |
| `SUPER + SHIFT + A` | Grok |
| `SUPER + SHIFT + ALT + A` | ChatGPT |
| `SUPER + SHIFT + L` | Lazygit |
| `SUPER + SHIFT + G` | GitHub |
| `SUPER + 1` / `2` / `3` / `8` / `9` | Workspace switch + label toast |
| `SUPER + SHIFT + I` | Asciiquarium |
| `SUPER + SHIFT + J` | Job Bot web (reuse `:17373` if running, else start + browser) |
| `SUPER + SHIFT + ALT + J` | Stop Job Bot web server |

`job-bot-web` (stowed to `~/.local/bin`) runs Vite on **17373** (not Vite’s default 5173). A second press reuses the existing server instead of starting another. `job-bot-web stop` kills the listener and closes its terminal. Override the repo with `JOB_BOT_DIR`.

### Shell / bar
Bar layout, idle, and widgets are configured in `omarchy/shell.json` (Quickshell / `omarchy-shell`):

- Left: menu, `slim.workspaces` (persistent 1–9 with icons), media, `slim.projects`
- Center: indicators, active window, clock, keyboard layout, system update
- Right: tray, tailscale, agents, bluetooth, network, audio, `slim.cpu` / `slim.memory` / `slim.disk`, monitor, power

Custom plugins live under `omarchy/plugins/` (`slim.workspaces`, `slim.cpu`, `slim.memory`, `slim.disk`, `slim.projects`). Stats use `omarchy/bar/scripts/system-stats`. Third-party plugin git URLs are listed in `plugin-sources.json` (see [Install third-party plugins](#install-third-party-plugins)).

### Cursor
Only `cursor/User/keybindings.json` is stowed (to `~/.config/Cursor/User/keybindings.json`). The rest of `~/.config/Cursor` stays local so History, storage, and `settings.json` are not overwritten.

Linux Cursor paste/copy in the integrated terminal is Ctrl+Shift+V / Ctrl+Shift+C. Omarchy Super+V / Super+C inject Ctrl+V / Ctrl+C into non-terminal windows, so these remaps apply when the terminal is focused:

| Keybinding | Action | When |
|------------|--------|------|
| `ctrl+v` | Paste | `terminalFocus` |
| `ctrl+c` | Copy selection | `terminalFocus && terminalTextSelected` |

Without a selection, Super+C / Ctrl+C still interrupts the running command.

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
`omarchy/plugins/slim.projects` is an Omarchy overlay plugin (Quickshell) that searches project directories and opens them in a configured editor. Bound to `SUPER+SHIFT+ALT+Space`. A folder icon on the left of the bar opens a panel to edit scan folders and pinned projects (right-click opens the picker).

Configure search roots, pinned projects, and editors in `omarchy/projects.json` (stowed to `~/.config/omarchy/projects.json`), or use the bar panel for folders and pinned projects:

```json
{
  "defaultEditor": "cursor",
  "baseDirs": ["~/Documents/dev"],
  "projects": [
    { "label": "Custom Dotfiles", "path": "~/.dotfiles" },
    { "label": "Omarchy Config", "path": "/usr/share/omarchy" },
    { "label": "OpenClaw Config", "path": "~/.openclaw" }
  ],
  "editors": [
    { "id": "cursor", "name": "Cursor", "command": ["/usr/bin/cursor", "-n", "--classic"], "class": "cursor", "kind": "gui" },
    { "id": "nvim", "name": "Neovim", "command": ["nvim"], "kind": "tui" }
  ]
}
```
