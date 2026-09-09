-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
hl.workspace_rule({ workspace = "1", monitor = "DP-5", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-5", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-5", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-5", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "DP-5", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "DP-5", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "DP-5", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "DP-5", persistent = true })
