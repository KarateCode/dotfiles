local settings = require("settings")
local colors = require("colors")

-- Detect if built-in display has a notch (MacBook Pro 14"/16" from 2021+)
-- Built-in display is typically display 1
local function is_notch_display(display_id)
  -- Display 1 is usually the built-in display on MacBooks
  return display_id == 1
end

local cal = sbar.add("item", "calendar", {
  icon = {
    color = colors.white,
    padding_left = 8,
    font = {
      -- style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 8,
    width = 69,
    align = "right",
    font = {
      -- family = settings.font.numbers,
      style = settings.font.style_map["Black"],
    },
  },
  position = "e",  -- Start at "e" (right of notch) - works on all displays
  update_freq = 30,
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.bg2,
    border_color = colors.black,
    border_width = 1
  },
  click_script = "open -a 'Calendar'"
})

-- Double border for calendar using a single item bracket
local cal_bracket = sbar.add("bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.grey,
  }
})

cal:subscribe({ "forced", "routine", "system_woke" }, function(env)
    local time_with_zero = os.date("%I:%M%p")
    local time_no_zero = time_with_zero:gsub("^0(%d)", "%1")

    cal:set({ icon = os.date("%a %b %d"), label = time_no_zero })
end)
