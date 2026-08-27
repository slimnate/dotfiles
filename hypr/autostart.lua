-- Extra apps to start with the session.
-- Window placement/opacity rules live in windows.lua.

-- Cursor: use /usr/bin/cursor (not the ~/.local/bin shim) and delay until
-- Omarchy's hyprland.start import-environment finishes — otherwise the shim
-- can't find the real binary and no window appears. --classic opens the IDE
-- instead of Cursor 3's Agents/glass window.
o.exec_on_start("sleep 2 && " .. o.launch("/usr/bin/cursor --classic"))
o.launch_on_start("microsoft-edge-stable")

-- Omarchy TUI launcher sets app-id org.omarchy.lazygit (matches windows.lua).
-- Foot ignores --app-id for Hyprland class; use Alacritty so window rules match.
o.exec_on_start(o.launch("alacritty --class org.omarchy.lazygit --title lazygit -e lazygit"))

-- Joplin is installed as an AppImage (joplin-desktop is not on PATH).
o.launch_on_start(os.getenv("HOME") .. "/.joplin/Joplin.AppImage")

o.exec_on_start("omarchy-launch-spotify")

-- Windscribe is started by ~/.config/autostart/windscribe.desktop (--autostart).
-- That flag only restores firewall state; "Start Minimized" uses showMinimized(),
-- which Hyprland does not implement. Closing the window also quits the app
-- (WM close is not close-to-tray). Park the first window on a silent special
-- workspace so login leaves it in the tray; later tray clicks still raise it.
local windscribe_hide_until = 0

hl.on("hyprland.start", function()
  windscribe_hide_until = os.time() + 30
end)

hl.on("window.open", function(window)
  if not window or window.class ~= "Windscribe" then
    return
  end
  if os.time() >= windscribe_hide_until then
    return
  end
  hl.dispatch(hl.dsp.window.move({
    workspace = "special:windscribe",
    follow = false,
    window = window,
  }))
end)
