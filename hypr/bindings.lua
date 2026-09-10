-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- 1. Clear the default Super bindings so they don't conflict
hl.unbind("SUPER + code:10")
hl.unbind("SUPER + code:11")
hl.unbind("SUPER + code:12")
hl.unbind("SUPER + code:13")
hl.unbind("SUPER + code:14")
hl.unbind("SUPER + code:15")
hl.unbind("SUPER + code:16")
hl.unbind("SUPER + code:17")
hl.unbind("SUPER + code:18")
-- 2. Bind your new keys (e.g., mapping to Alt + Number)
-- Syntax: o.bind("KEYS", "Description/Label", "Hyprland Dispatcher")
-- o.bind("ALT + 1", "Switch to workspace 1", { dispatch = "workspace, 1" })

o.bind("ALT + 1", "Switch to workspace 1", function()
    hl.dispatch(hl.dsp.focus({ workspace = "1" }))
end)
o.bind("ALT + 2", "Switch to workspace 2", function()
    hl.dispatch(hl.dsp.focus({ workspace = "2" }))
end)
o.bind("ALT + 3", "Switch to workspace 3", function()
    hl.dispatch(hl.dsp.focus({ workspace = "3" }))
end)
o.bind("ALT + 4", "Switch to workspace 4", function()
    hl.dispatch(hl.dsp.focus({ workspace = "4" }))
end)
o.bind("ALT + 5", "Switch to workspace 5", function()
    hl.dispatch(hl.dsp.focus({ workspace = "5" }))
end)
o.bind("ALT + 6", "Switch to workspace 6", function()
    hl.dispatch(hl.dsp.focus({ workspace = "6" }))
end)
o.bind("ALT + 7", "Switch to workspace 7", function()
    hl.dispatch(hl.dsp.focus({ workspace = "7" }))
end)
o.bind("ALT + 8", "Switch to workspace 8", function()
    hl.dispatch(hl.dsp.focus({ workspace = "8" }))
end)
o.bind("ALT + 9", "Switch to workspace 9", function()
    hl.dispatch(hl.dsp.focus({ workspace = "9" }))
end)

-- o.bind("ALT + 2", "Workspace 2", "workspace, 2")

-- Chromium tab navigation: CTRL+ALT+Left / CTRL+ALT+Right.
--
-- Chromium's own prev/next tab keys are CTRL+Page_Up / CTRL+Page_Down, so these
-- bindings just forward that shortcut to the focused window.
--
-- The class check matters: send_shortcut with window = "class:chromium" would
-- fire even when Chromium is NOT focused, flipping tabs in a background window
-- while you type somewhere else. Guarding on the active window means the keys
-- are inert unless Chromium actually has focus.
--
-- Note the class is lowercase "chromium" (verify with `hyprctl clients`).
local function chromium_tab(key)
    return function()
        local win = hl.get_active_window()
        if win and win.class == "chromium" then
            hl.dispatch(hl.dsp.send_shortcut({
                mods = "CTRL",
                key = key,
                window = "activewindow",
            }))
        end
    end
end

o.bind("CTRL + ALT + Left", "Chromium: previous tab", chromium_tab("Page_Up"))
o.bind("CTRL + ALT + Right", "Chromium: next tab", chromium_tab("Page_Down"))
