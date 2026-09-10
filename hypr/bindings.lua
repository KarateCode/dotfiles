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
-- IMPORTANT: these keys are shared. tmux binds C-M-Left/C-M-Right to
-- previous-window/next-window (tmux_omarchy.conf). A Hyprland bind grabs the
-- key at the compositor, BEFORE any app sees it, so an always-on bind here
-- silently steals the keys from tmux. Checking the focused class inside the
-- handler does not help -- the key is already swallowed by then.
--
-- So the binds are only ENABLED while Chromium is focused. While they are
-- disabled Hyprland does not grab the keys at all, and they pass through to
-- the terminal (and therefore tmux) normally.
--
-- hl.bind is used instead of o.bind because o.bind returns nil, and we need
-- the HL.Keybind handles to call set_enabled on.
--
-- Note the class is lowercase "chromium" (verify with `hyprctl clients`).
local function chromium_tab(key)
    return function()
        hl.dispatch(hl.dsp.send_shortcut({
            mods = "CTRL",
            key = key,
            window = "activewindow",
        }))
    end
end

local chromium_tab_binds = {
    hl.bind("CTRL + ALT + Left", chromium_tab("Page_Up"), {
        description = "Chromium: previous tab",
    }),
    hl.bind("CTRL + ALT + Right", chromium_tab("Page_Down"), {
        description = "Chromium: next tab",
    }),
}

local function sync_chromium_tab_binds()
    local win = hl.get_active_window()
    local focused = (win ~= nil and win.class == "chromium")

    for _, keybind in ipairs(chromium_tab_binds) do
        keybind:set_enabled(focused)
    end
end

hl.on("window.active", sync_chromium_tab_binds)
sync_chromium_tab_binds()
