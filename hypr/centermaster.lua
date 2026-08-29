-- Center-master layout with horizontal sub-splits on the side stacks.
--
-- Hyprland's master layout (orientation=center) can only stack side windows
-- vertically, so a 6th window makes a side column three short rows. This
-- replaces it:
--   1 window   : centered at mfact width (master's always_keep_position look).
--   2-5 windows: identical to master center — slaves alternate left,right and
--                stack vertically (at most 2 rows per side).
--   6+ windows : dwindle-ish, but each side exhausts one split direction
--                before switching: rows split horizontally up to 2x2 per side
--                (9 windows), then vertically up to 4x2 (17), then
--                horizontally again to 4x4, alternating forever. The main
--                (first) window never splits or shrinks.
--
-- layout_msg: "mfact <value>" or "mfact +/-<delta>" adjusts the main width.

local M = { mfact = nil }

-- Read master.mfact lazily: this file is required before hl.config() runs,
-- so the configured value only exists once the first recalculate fires.
local function mfact()
  if not M.mfact then
    M.mfact = 0.5
    local ok, v = pcall(hl.get_config, "master.mfact")
    if ok and type(v) == "number" and v > 0 and v < 1 then M.mfact = v end
  end
  return M.mfact
end

-- Recursively halve the box, alternating direction by depth: even depths
-- split top/bottom, odd depths left/right. The first window claims the
-- first half; each following window joins the half with fewer windows
-- (second half on ties). This keeps existing windows in place as new ones
-- arrive, and each direction fills evenly before the next one starts:
-- 1x1 -> 2x1 -> 2x2 -> 4x2 -> 4x4 -> ... per side.
local function place_split(wins, x, y, w, h, depth)
  local k = #wins
  if k == 0 then return end
  if k == 1 then
    wins[1]:place({ x = x, y = y, w = w, h = h })
    return
  end
  local first, second = { wins[1] }, {}
  for i = 2, k do
    if #first < #second then
      first[#first + 1] = wins[i]
    else
      second[#second + 1] = wins[i]
    end
  end
  if depth % 2 == 0 then
    local rh = h / 2
    place_split(first, x, y, w, rh, depth + 1)
    place_split(second, x, y + rh, w, rh, depth + 1)
  else
    local cw = w / 2
    place_split(first, x, y, cw, h, depth + 1)
    place_split(second, x + cw, y, cw, h, depth + 1)
  end
end

hl.layout.register("centermaster", {
  recalculate = function(ctx)
    local n = #ctx.targets
    if n == 0 then return end
    local a = ctx.area
    local mw = a.w * mfact()
    local sw = (a.w - mw) / 2
    ctx.targets[1]:place({ x = a.x + sw, y = a.y, w = mw, h = a.h })
    if n == 1 then return end
    local left, right = {}, {}
    for i = 2, n do
      if i % 2 == 0 then
        left[#left + 1] = ctx.targets[i]
      else
        right[#right + 1] = ctx.targets[i]
      end
    end
    place_split(left, a.x, a.y, sw, a.h, 0)
    place_split(right, a.x + sw + mw, a.y, sw, a.h, 0)
  end,

  layout_msg = function(ctx, msg)
    local arg = msg:match("^mfact%s+([%+%-]?%d*%.?%d+)$")
    if not arg then return "unknown message: " .. msg end
    local v = tonumber(arg)
    if not v then return "bad mfact value" end
    if arg:match("^[%+%-]") then
      M.mfact = mfact() + v
    else
      M.mfact = v
    end
    M.mfact = math.max(0.2, math.min(0.8, M.mfact))
    return true
  end,
})
