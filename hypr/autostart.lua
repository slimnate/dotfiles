-- Extra apps to start with the session.
-- Window placement/opacity rules live in windows.lua.

-- Cursor: use /usr/bin/cursor (not the ~/.local/bin shim) and delay until
-- Omarchy's hyprland.start import-environment finishes — otherwise the shim
-- can't find the real binary and no window appears.
o.exec_on_start("sleep 2 && " .. o.launch("/usr/bin/cursor"))
o.launch_on_start("microsoft-edge-stable")

-- Omarchy TUI launcher sets app-id org.omarchy.lazygit (matches windows.lua).
-- Foot ignores --app-id for Hyprland class; use Alacritty so window rules match.
o.exec_on_start(o.launch("alacritty --class org.omarchy.lazygit --title lazygit -e lazygit"))

-- Joplin is installed as an AppImage (joplin-desktop is not on PATH).
o.launch_on_start(os.getenv("HOME") .. "/.joplin/Joplin.AppImage")

o.exec_on_start("omarchy-launch-spotify")
