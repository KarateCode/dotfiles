-- Global workspaces, replacing Omarchy's per-monitor blocks.
--
-- Omarchy's default (see $OMARCHY_PATH/default/hypr/monitor-workspaces.lua)
-- gives every monitor its own workspaces 1-10, Niri-style. Hyprland numbers
-- workspaces globally, so it implements that by handing each monitor a block
-- of ten ids -- the laptop 1-10, the next monitor 11-20 -- and relabelling
-- them 1-10 per bar. It records the assignment in
-- ~/.local/state/omarchy/monitor-workspaces, and reconciles on every start,
-- config reload and monitor hotplug, renumbering workspaces into the block of
-- whichever monitor they are sitting on.
--
-- hypr/monitors.lua pins global workspaces 1-9 to specific monitors by rule
-- (3 on the laptop panel, the rest on the Philips), and hypr/bindings.lua
-- switches and moves windows with literal workspace numbers. The two models
-- fight each other, in two visible ways:
--
--   * The Philips was assigned block 1, so its bar drew slots 11-15 relabelled
--     "1 2 3 4 5" and then listed the real workspaces living on it (1,2,4-9)
--     after them as "guests" -- the "1 2 3 4 5 1 2 4 5 6 7 8 9" row. The
--     laptop looked correct only because its block, 1-10, happens to match the
--     real numbers.
--   * reconcile() renumbers any workspace holding windows whose block belongs
--     to another monitor. Workspace 2 lives on the Philips but is in block 0,
--     so a config reload would rename it to 12 -- breaking ALT+2 and the
--     workspace rule that pins it.
--
-- This module is substituted for the Omarchy one in hypr/hyprland.lua. It
-- keeps the same `o.workspaces` API, because the default bindings in
-- $OMARCHY_PATH/default/hypr/bindings/tiling.lua and the omarchy.workspaces
-- bar widget both call it, but every slot is simply the global workspace of
-- that number and nothing is ever renumbered or reconciled.
--
-- With no state file present the bar widget falls back to block 0 and draws
-- workspaces 1-9 under their real numbers on both monitors, which is what we
-- want. Removing this module and deleting hypr/monitors.lua's workspace_rule
-- lines restores stock Omarchy behaviour.

local M = {}

-- Kept for API parity with the module this replaces; nothing reads it here.
M.slots = 10

-- Bind actions return functions for hl.dispatch, so `hyprctl dispatch
-- 'o.workspaces.focus(3)'` runs the same thing as the key. The keybindings
-- menu and the bar widget both replay binds through that expression.
local function action(fn, expression)
  o.bind_expressions[fn] = expression
  return fn
end

local function literal(value)
  if value == nil then
    return "nil"
  end
  return string.format("%q", value)
end

-- A slot is just its global workspace number.
function M.workspace_id(_, slot)
  return slot
end

-- Go to a workspace. `monitor_name` is accepted because the bar widget passes
-- the monitor whose bar was clicked, but it is ignored: the workspace rules in
-- hypr/monitors.lua already decide which monitor a workspace appears on, and
-- focusing it there is exactly what ALT+1..9 does. Honouring the argument
-- would drag the workspace onto the clicked monitor instead.
function M.focus(slot, monitor_name)
  return action(function()
    hl.dispatch(hl.dsp.focus({ workspace = tostring(slot) }))
  end, "o.workspaces.focus(" .. slot .. (monitor_name and ", " .. literal(monitor_name) or "") .. ")")
end

-- Move the active window to a workspace, following it unless `follow` is false.
function M.move_window(slot, follow)
  return action(function()
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(slot), follow = follow ~= false }))
  end, "o.workspaces.move_window(" .. slot .. (follow == false and ", false" or "") .. ")")
end

-- Move the active workspace to the monitor in a direction. The monitor is
-- resolved first because Hyprland reports a move toward no monitor as an error
-- on screen.
function M.move_to_monitor(direction)
  return action(function()
    local target = hl.get_monitor(direction)
    if target then
      hl.dispatch(hl.dsp.workspace.move({ monitor = target.name }))
    end
  end, "o.workspaces.move_to_monitor(" .. literal(direction) .. ")")
end

-- Move the focused window onto the workspace the monitor in that direction
-- shows, and follow it there.
function M.move_window_to_monitor(direction)
  return action(function()
    local target = hl.get_monitor(direction)
    if target then
      hl.dispatch(hl.dsp.window.move({ monitor = target.name }))
    end
  end, "o.workspaces.move_window_to_monitor(" .. literal(direction) .. ")")
end

-- Nothing to reconcile without blocks. Defined because the module this
-- replaces exports it.
function M.reconcile() end

o.workspaces = M

return M
