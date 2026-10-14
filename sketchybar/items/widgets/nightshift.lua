local colors = require("colors")
local settings = require("settings")

local nightshift = sbar.add("item", "widgets.nightshift", {
  position = "right",
  icon = {
    string = "󰖔", -- moon icon (off state)
    font = {
      style = settings.font.style_map["Regular"],
      size = 17.0,
    },
    color = colors.grey,
  },
  label = { drawing = false },
  update_freq = 30,
})

local function update_icon()
  sbar.exec("/opt/homebrew/bin/nightlight status", function(result)
    if result:match("on") then
      nightshift:set({
        icon = { string = "󰖔", color = colors.orange },
      })
    else
      nightshift:set({
        icon = { string = "󰖔", color = colors.grey },
      })
    end
  end)
end

nightshift:subscribe("mouse.clicked", function()
  sbar.exec("/opt/homebrew/bin/nightlight toggle", function()
    update_icon()
  end)
end)

nightshift:subscribe({"routine", "system_woke", "forced"}, function()
  update_icon()
end)

sbar.add("bracket", "widgets.nightshift.bracket", { nightshift.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.nightshift.padding", {
  position = "right",
  width = settings.group_paddings
})
