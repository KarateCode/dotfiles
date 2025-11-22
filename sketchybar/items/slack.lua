-- items/slack.lua
-- Slack widget item definition for SketchyBar
sbar.add("item", { width = 5 })

local slack = {
  icon = {
    font = { size = 20.0 },
    string = "󰒱",
    padding_right = 8,
    padding_left = 8,
  },
  ["icon.padding_right"] = -26,
  -- ["icon.padding_left"] = 18,

  label = {
    background = {
      color = 0xffe8433a,
      height = 18,
      corner_radius = 9,
      drawing = true,
    },
    padding_left = 10,
    width = 25,
  },

  script = "$CONFIG_DIR/scripts/slack.sh",
  update_freq = 10,
  updates = true,
  drawing = true,
  background = {
    color = 0x00000000,
  },
}

sbar.add("item", slack)
-- Optionally place it on the right side
sbar.set("slack", { position = "right" })
-- return slack
