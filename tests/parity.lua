local GHOSTTY = "extras/ghostty/arrakis"

-- Ghostty accepts surrounding whitespace and either hex case. The parity
-- test must survive a reformat without reporting drift, and must still
-- catch a real value change.
local function parse(path)
  local fh = assert(io.open(path, "r"), "cannot open " .. path)
  local conf = { palette = {} }

  for line in fh:lines() do
    local stripped = line:gsub("^%s+", ""):gsub("%s+$", "")
    if stripped ~= "" and stripped:sub(1, 1) ~= "#" then
      local index, colour = stripped:match("^palette%s*=%s*(%d+)%s*=%s*(#?%x%x%x%x%x%x)$")
      if index then
        conf.palette[tonumber(index)] = "#" .. colour:gsub("^#", ""):lower()
      else
        local key, value = stripped:match("^([%w%-]+)%s*=%s*(.+)$")
        if key then
          conf[key] = value:gsub("^#", ""):lower()
        end
      end
    end
  end

  fh:close()
  return conf
end

return function(t)
  local p = require("arrakis.palette")
  local conf = parse(GHOSTTY)

  for i = 0, 15 do
    local want = p.ansi[i]:gsub("^#", "")
    local got = conf.palette[i] and conf.palette[i]:gsub("^#", "") or nil
    t.check(
      string.format("ghostty palette %d", i),
      got == want,
      string.format("got %s, want %s", tostring(got), want)
    )
  end

  local scalars = {
    background = p.bg,
    foreground = p.fg,
    ["cursor-color"] = p.spice,
    ["cursor-text"] = p.bg,
    ["selection-background"] = p.bg_sel,
    ["selection-foreground"] = p.fg,
  }

  for key, want_hex in pairs(scalars) do
    local want = want_hex:gsub("^#", "")
    t.check(
      "ghostty " .. key,
      conf[key] == want,
      string.format("got %s, want %s", tostring(conf[key]), want)
    )
  end

  -- Bright-on-bold would promote a colour every time a program bolds text,
  -- undoing the restraint rule outside the editor.
  t.check("ghostty bold-is-bright false", conf["bold-is-bright"] == "false", tostring(conf["bold-is-bright"]))

  -- vim.g.terminal_color_* must match the same 16, so :terminal and a bare
  -- Ghostty shell are indistinguishable.
  require("arrakis").setup({})
  vim.cmd.colorscheme("arrakis")

  for i = 0, 15 do
    local got = vim.g["terminal_color_" .. i]
    t.check(
      string.format("terminal_color_%d", i),
      got == p.ansi[i],
      string.format("got %s, want %s", tostring(got), p.ansi[i])
    )
  end
end
