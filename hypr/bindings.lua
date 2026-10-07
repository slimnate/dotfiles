-- Keep only personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.
--
-- See current bindings: omarchy menu keybindings --print

-- Cursor (replaces Calendar on SUPER+SHIFT+C).
-- Use /usr/bin/cursor (not the ~/.local/bin shim) plus --classic so Cursor 3
-- opens the IDE window instead of Agents/glass. { launch = ... } wraps uwsm-app.
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Code Editor (Cursor)", {
  launch = "/usr/bin/cursor --classic",
})
o.bind("SUPER + SHIFT + ALT + SPACE", "Projects", "omarchy-shell shell toggle slim.projects")

-- Swap AI shortcuts vs Omarchy defaults (Grok on A, ChatGPT on ALT+A).
hl.unbind("SUPER + SHIFT + A")
hl.unbind("SUPER + SHIFT + ALT + A")
o.bind("SUPER + SHIFT + A", "Grok", { webapp = "https://grok.com" })
o.bind("SUPER + SHIFT + ALT + A", "ChatGPT", { webapp = "https://chatgpt.com" })

-- Lazygit + GitHub (GitHub replaces Signal on SUPER+SHIFT+G).
o.bind("SUPER + SHIFT + L", "Lazygit", {
  focus = "org.omarchy.lazygit",
  launch = "alacritty --class org.omarchy.lazygit --title lazygit -e lazygit",
})
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "GitHub", { webapp = "https://github.com/" })

-- Workspace switch + label toast (also keeps focus — old conf only notified).
-- Omarchy binds these as SUPER + code:10..18 for workspaces 1..9.
local workspace_labels = {
  [1] = "CODE",
  [2] = "BROWSER",
  [3] = "LAZYGIT",
  [8] = "NOTES",
  [9] = "SPOTIFY",
}

for id, label in pairs(workspace_labels) do
  local keys = "SUPER + code:" .. tostring(id + 9)
  hl.unbind(keys)
  o.bind(keys, "Workspace " .. id .. " (" .. label .. ")", function()
    hl.dispatch(hl.dsp.focus({ workspace = tostring(id) }))
    hl.exec_cmd(('hyprctl notify 2 1000 "rgb(8D00FA)" "fontsize:18 %s"'):format(label))
  end)
end

-- SUPER+SHIFT+ALT+LEFT/RIGHT already move the workspace between monitors in
-- Omarchy defaults (the old conf's movecurrentworkspacetomonitor binds were broken).

-- Asciiquarium
o.bind("SUPER + SHIFT + I", "Asciiquarium", "alacritty --title asciiquarium -e asciiquarium")

-- Toolroll
o.bind("SUPER + SHIFT + T", "Toolroll", "omarchy-shell shell toggle io.github.iainfreestone.toolroll")

-- Snitch   
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Snitch", "omarchy-shell shell toggle io.github.mvanthoor.snitch")

-- Job Bot web UI on :17373 (reuse if already running).
o.bind("SUPER + SHIFT + J", "Job Bot Web", os.getenv("HOME") .. "/.local/bin/job-bot-web")
o.bind("SUPER + SHIFT + ALT + J", "Job Bot Web Stop", os.getenv("HOME") .. "/.local/bin/job-bot-web stop")