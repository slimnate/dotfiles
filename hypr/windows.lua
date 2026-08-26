-- Window rules: workspace assignment + opacity overrides.
-- Ported from windows.conf and the windowrule block in autostart.conf.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Workspace / monitor placement (silent = don't steal focus on open).
o.window("cursor", { workspace = "1 silent", monitor = "DP-1" })
o.window("microsoft-edge", { workspace = "2 silent", monitor = "DP-2" })
-- Lazygit: old class was org.omarchy.lazygit; autostart uses --title lazygit.
o.window("org.omarchy.lazygit", { workspace = "3 silent", monitor = "DP-2" })
o.window({ title = "^lazygit$" }, { workspace = "3 silent", monitor = "DP-2" })
-- Live class confirmed via hyprctl clients (not joplin-app-desktop).
o.window("^(@joplin/app-desktop)$", { workspace = "8 silent", monitor = "DP-2" })
o.window("^([Ss]potify)$", { workspace = "9 silent", monitor = "DP-2" })

o.window({ title = "^(asciiquarium)$" }, { fullscreen = true })

-- Opacity: Omarchy applies ~0.985/0.96 via a default-opacity tag.
-- Opt specific apps out (don't use a named .* rule — named rules lose to defaults).
-- Edge is already near-opaque via browser.lua; force fully opaque like the old conf.
o.window("microsoft-edge", { opacity = "1 1" })
o.window("^([Ss]potify)$", { tag = "-default-opacity", opacity = "1 1" })
o.window("^(@joplin/app-desktop)$", { tag = "-default-opacity", opacity = "1 1" })
