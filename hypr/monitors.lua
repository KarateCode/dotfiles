-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

local external = "desc:Philips Consumer Electronics Company PHL 276E8V"
local internal = "eDP-1"

hl.workspace_rule({ workspace = "1", monitor = external, default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = external, persistent = true })
hl.workspace_rule({ workspace = "3", monitor = internal, default = true, persistent = true })
hl.workspace_rule({ workspace = "4", monitor = external, persistent = true })
hl.workspace_rule({ workspace = "5", monitor = external, persistent = true })
hl.workspace_rule({ workspace = "6", monitor = external, persistent = true })
hl.workspace_rule({ workspace = "7", monitor = external, persistent = true })
hl.workspace_rule({ workspace = "8", monitor = external, persistent = true })
hl.workspace_rule({ workspace = "9", monitor = external, persistent = true })
