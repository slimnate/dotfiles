-- Host-specific overrides. Replaces input.profile.conf + laptop/desktop confs.
-- Detects laptop vs desktop via Omarchy's hardware helper (lid / chassis type).

local laptop = o.shell_succeeds("omarchy-hw-laptop")

-- From input.laptop.conf (0.05) and input.desktop.conf (-0.5).
hl.config({
  input = {
    sensitivity = laptop and 0.05 or -0.5,
  },
})
