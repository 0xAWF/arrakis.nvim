-- WCAG 2.1 relative luminance and contrast ratio, computed in plain Lua.
local function channel(byte)
  local c = byte / 255
  if c <= 0.04045 then
    return c / 12.92
  end
  return ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    error("malformed hex: " .. tostring(hex))
  end
  return 0.2126 * channel(tonumber(r, 16))
    + 0.7152 * channel(tonumber(g, 16))
    + 0.0722 * channel(tonumber(b, 16))
end

local function ratio(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

-- Thresholds from the spec. Comments and chrome sit below the text bar by
-- design, so they get their own lower bars rather than being exempted.
local thresholds = {
  fg_bright = 7,
  fg = 7,
  fg_dim = 7,
  ember = 4.5,
  spice = 4.5,
  ibad = 4.5,
  num = 4.5,
  scrub = 4.5,
  water = 4.5,
  melange = 4.5,
  blood = 4.5,
  subtle = 4.5,
  muted = 3,
  linenr = 2,
  border = 1.5,
}

return function(t)
  local p = require("arrakis.palette")

  -- Every value in the palette must be a well-formed hex string.
  for name, value in pairs(p) do
    if name ~= "ansi" then
      t.check(
        "hex format " .. name,
        type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil,
        string.format("got %s", tostring(value))
      )
    end
  end

  for i = 0, 15 do
    t.check(
      string.format("hex format ansi[%d]", i),
      type(p.ansi[i]) == "string" and p.ansi[i]:match("^#%x%x%x%x%x%x$") ~= nil,
      string.format("got %s", tostring(p.ansi[i]))
    )
  end

  for name, minimum in pairs(thresholds) do
    local got = ratio(p[name], p.bg)
    t.check(
      "contrast " .. name,
      got >= minimum,
      string.format("%.2f:1 against bg, need %.2f:1", got, minimum)
    )
  end
end
