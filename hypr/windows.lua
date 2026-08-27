-- Window rules: workspace assignment + opacity overrides.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

local laptop = o.shell_succeeds("omarchy-hw-laptop")

-- Desktop: pin workspaces to monitors so placement survives startup, unlock, and reload.
-- Laptop: keep persistent workspaces only (no DP-1/DP-2 names).
if laptop then
  for i = 1, 9 do
    hl.workspace_rule({ workspace = tostring(i), persistent = true })
  end
else
  hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true })
  for i = 2, 9 do
    hl.workspace_rule({ workspace = tostring(i), monitor = "DP-2", persistent = true })
  end
end

local function desktop_placement(workspace, monitor)
  if laptop then
    return { workspace = workspace .. " silent" }
  end
  return { workspace = workspace .. " silent", monitor = monitor }
end

-- Cursor → workspace 1 / DP-1
o.window("cursor", desktop_placement("1", "DP-1"))

-- Edge → workspace 2 / DP-2 (class is microsoft-edge even when launched as microsoft-edge-stable)
o.window("microsoft-edge", desktop_placement("2", "DP-2"))

-- Lazygit → workspace 3 / DP-2
-- Foot (default terminal) ignores --app-id for Hyprland class; launch via Alacritty instead.
o.window("org.omarchy.lazygit", desktop_placement("3", "DP-2"))
o.window({ title = "^lazygit$" }, desktop_placement("3", "DP-2"))

-- Joplin → workspace 8 / DP-2
o.window("^(@joplin/app-desktop)$", desktop_placement("8", "DP-2"))

-- Spotify → workspace 9 / DP-2
o.window("^([Ss]potify)$", desktop_placement("9", "DP-2"))

-- Asciiquarium fullscreen (SUPER+SHIFT+I)
o.window({ title = "^(asciiquarium)$" }, { fullscreen = true })

-- Opacity: Omarchy applies ~0.985/0.96 via a default-opacity tag.
o.window("microsoft-edge", { opacity = "1 1" })
o.window("^([Ss]potify)$", { tag = "-default-opacity", opacity = "1 1" })
o.window("^(@joplin/app-desktop)$", { tag = "-default-opacity", opacity = "1 1" })
