local colors = require("colors")
local settings = require("settings")

-- Aerospace workspace indicator
local aerospace = sbar.add("item", "aerospace", {
  icon = {
    font = { family = settings.font.numbers },
    string = "?",
    padding_left = 15,
    padding_right = 15,
    color = colors.white,
  },
  background = {
    color = colors.bg1,
    border_width = 1,
    height = 26,
    border_color = colors.black,
  },
  padding_right = 1,
  padding_left = 1,
})

-- Query current workspace on startup
sbar.exec("aerospace list-workspaces --focused", function(result)
  local workspace = result:gsub("%s+", "")
  aerospace:set({ icon = { string = workspace } })
end)

-- Subscribe to aerospace_workspace_change event
-- Add this to your aerospace.toml:
-- exec-on-workspace-change = ['/bin/bash', '-c', 'sketchybar --trigger aerospace_workspace_change']
aerospace:subscribe("aerospace_workspace_change", function(env)
  sbar.exec("aerospace list-workspaces --focused", function(result)
    local workspace = result:gsub("%s+", "")
    aerospace:set({ icon = { string = workspace } })
  end)
end)

-- Click to open workspace switcher (optional)
aerospace:subscribe("mouse.clicked", function(env)
  sbar.exec("aerospace workspace-back-and-forth")
end)
