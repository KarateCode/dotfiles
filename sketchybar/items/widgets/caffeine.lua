local colors = require("colors")
local settings = require("settings")

local caffeine = sbar.add("item", "widgets.caffeine", {
  position = "right",
  icon = {
    string = "󰒲", -- sleep icon (off state)
    font = {
      style = settings.font.style_map["Regular"],
      size = 17.0,
    },
    color = colors.grey,
  },
  label = { drawing = false },
  script = "$CONFIG_DIR/scripts/caffeine.sh",
  click_script = "$CONFIG_DIR/scripts/caffeine.sh toggle",
  update_freq = 30,
})

-- Check initial state on load and routine updates
caffeine:subscribe({"routine", "system_woke", "forced"}, function()
  sbar.exec("pgrep -x caffeinate", function(result)
    if result ~= "" then
      caffeine:set({
        icon = { string = "󰛊", color = colors.yellow },
      })
    else
      caffeine:set({
        icon = { string = "󰒲", color = colors.grey },
      })
    end
  end)
end)

sbar.add("bracket", "widgets.caffeine.bracket", { caffeine.name }, {
  background = { color = colors.bg1 }
})

sbar.add("item", "widgets.caffeine.padding", {
  position = "right",
  width = settings.group_paddings
})
