-- Extra apps to start with the session.
-- Window placement/opacity rules live in windows.lua.

o.launch_on_start("cursor")
o.launch_on_start("microsoft-edge-stable")

-- Omarchy TUI launcher sets app-id org.omarchy.lazygit (matches windows.lua).
-- Old `$TERMINAL --title lazygit` was unreliable with exec-once.
o.exec_on_start("omarchy-launch-tui lazygit")

-- Joplin is installed as an AppImage (joplin-desktop is not on PATH).
o.launch_on_start(os.getenv("HOME") .. "/.joplin/Joplin.AppImage")

o.exec_on_start("omarchy-launch-spotify")
