-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all
-- You must relaunch Hyprland after changing any envs (Super+Esc → Relaunch)

-- Kept from pre-Quattro monitors.conf (retina-class GDK scale with 1x monitor scale).
local omarchy_gdk_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))

-- Fallback for any unmatched output (e.g. laptop panel).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- Desktop dual 1440p at each panel's max refresh (side by side).
hl.monitor({ output = "DP-1", mode = "2560x1440@164.84", position = "0x0", scale = 1 })
hl.monitor({ output = "DP-2", mode = "2560x1440@180", position = "2560x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
