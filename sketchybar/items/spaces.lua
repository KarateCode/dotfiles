local colors = require("colors")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

-- Aerospace workspace indicator
local aerospace = sbar.add("item", "space.aerospace", {
  icon = {
    font = { family = settings.font.numbers },
    string = "?",
    padding_left = 15,
    padding_right = 8,
    color = colors.red,
  },
  label = {
    padding_right = 15,
    color = colors.grey,
    highlight_color = colors.white,
    font = "sketchybar-app-font:Regular:16.0",
    y_offset = -1,
    string = "",
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

-- Function to get app icons for current workspace
local function update_app_icons()
  sbar.exec("aerospace list-windows --workspace focused --format '%{app-name}'", function(result)
    local icon_line = ""
    local seen_apps = {}

    for app in result:gmatch("[^\r\n]+") do
      -- Only show each app icon once
      if not seen_apps[app] then
        seen_apps[app] = true
        local lookup = app_icons[app]
        local icon = lookup or app_icons["Default"]
        icon_line = icon_line .. icon
      end
    end

    if icon_line == "" then
      icon_line = " —"
    end

    sbar.animate("tanh", 10, function()
      aerospace:set({ label = { string = icon_line } })
    end)
  end)
end

-- Query current workspace on startup
sbar.exec("aerospace list-workspaces --focused", function(result)
  local workspace = result:gsub("%s+", "")
  aerospace:set({ icon = { string = workspace } })
  update_app_icons()
end)

-- Subscribe to aerospace_workspace_change event
-- Add this to your aerospace.toml:
-- exec-on-workspace-change = ['/bin/bash', '-c', 'sketchybar --trigger aerospace_workspace_change']
aerospace:subscribe("aerospace_workspace_change", function(env)
  sbar.exec("aerospace list-workspaces --focused", function(result)
    local workspace = result:gsub("%s+", "")
    aerospace:set({ icon = { string = workspace } })
    update_app_icons()
  end)
end)

-- Subscribe to front_app_switched to update icons when apps change
aerospace:subscribe("front_app_switched", function(env)
  update_app_icons()
end)

-- Click to open workspace switcher (optional)
aerospace:subscribe("mouse.clicked", function(env)
  sbar.exec("aerospace workspace-back-and-forth")
end)

-- Spaces indicator (toggle switch) - stays visible to allow toggling back from menus
local icons = require("icons")

local spaces_indicator = sbar.add("item", {
  padding_left = -3,
  padding_right = 0,
  icon = {
    padding_left = 8,
    padding_right = 9,
    color = colors.grey,
    string = icons.switch.on,
  },
  label = {
    width = 0,
    padding_left = 0,
    padding_right = 8,
    string = "Spaces",
    color = colors.bg1,
  },
  background = {
    color = colors.with_alpha(colors.grey, 0.0),
    border_color = colors.with_alpha(colors.bg1, 0.0),
  }
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
  local currently_on = spaces_indicator:query().icon.value == icons.switch.on
  spaces_indicator:set({
    icon = currently_on and icons.switch.off or icons.switch.on
  })
end)

spaces_indicator:subscribe("mouse.entered", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 1.0 },
        border_color = { alpha = 1.0 },
      },
      icon = { color = colors.bg1 },
      label = { width = "dynamic" }
    })
  end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
  sbar.animate("tanh", 30, function()
    spaces_indicator:set({
      background = {
        color = { alpha = 0.0 },
        border_color = { alpha = 0.0 },
      },
      icon = { color = colors.grey },
      label = { width = 0, }
    })
  end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)
