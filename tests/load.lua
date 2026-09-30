-- Resolve a highlight group to a concrete definition.
local function hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

-- nvim_get_hl returns colours as integers; compare against palette hex.
local function hex(n)
  if n == nil then
    return nil
  end
  return string.format("#%06x", n)
end

return function(t)
  local p = require("arrakis.palette")

  -- Loading must not error, and must set colors_name.
  local ok, err = pcall(vim.cmd.colorscheme, "arrakis")
  t.check("colorscheme loads", ok, tostring(err))
  t.check("colors_name set", vim.g.colors_name == "arrakis", tostring(vim.g.colors_name))

  -- Review Focus 1: reloading. `hi clear` wipes colors_name mid-load; a
  -- second load must not error or leave the scheme half-applied.
  local ok2, err2 = pcall(vim.cmd.colorscheme, "arrakis")
  t.check("colorscheme reloads", ok2, tostring(err2))
  t.check("colors_name after reload", vim.g.colors_name == "arrakis", tostring(vim.g.colors_name))

  -- Core chrome resolves to the palette, not to nothing.
  t.check("Normal fg", hex(hl("Normal").fg) == p.fg, tostring(hex(hl("Normal").fg)))
  t.check("Normal bg", hex(hl("Normal").bg) == p.bg, tostring(hex(hl("Normal").bg)))
  t.check("CursorLine bg", hex(hl("CursorLine").bg) == p.bg_alt, tostring(hex(hl("CursorLine").bg)))
  t.check("CursorLineNr fg", hex(hl("CursorLineNr").fg) == p.spice, tostring(hex(hl("CursorLineNr").fg)))
  t.check("LineNr fg", hex(hl("LineNr").fg) == p.linenr, tostring(hex(hl("LineNr").fg)))
  t.check("ColorColumn bg", hex(hl("ColorColumn").bg) == p.bg_alt, tostring(hex(hl("ColorColumn").bg)))
  t.check("Visual bg", hex(hl("Visual").bg) == p.bg_sel, tostring(hex(hl("Visual").bg)))
  t.check("NormalFloat bg", hex(hl("NormalFloat").bg) == p.bg_float, tostring(hex(hl("NormalFloat").bg)))
  t.check("FloatBorder fg", hex(hl("FloatBorder").fg) == p.border, tostring(hex(hl("FloatBorder").fg)))

  -- The spec writes chrome as "<fg> on <bg>" (IncSearch `bg` on `spice`,
  -- StatusLine `fg_dim` on `bg_alt`). Search is `bg_sel` on `fg`: a bright
  -- sand block with dark text. Reversed, its background is bg_sel — which
  -- is also Visual, PmenuSel and TelescopeSelection — so every non-current
  -- match becomes invisible and indistinguishable from a selection.
  t.check("Search fg", hex(hl("Search").fg) == p.bg_sel, tostring(hex(hl("Search").fg)))
  t.check("Search bg", hex(hl("Search").bg) == p.fg, tostring(hex(hl("Search").bg)))
  t.check("Search bg differs from Visual bg", hex(hl("Search").bg) ~= hex(hl("Visual").bg), "Search is indistinguishable from Visual")

  -- No group may resolve to an empty definition.
  for _, group in ipairs({ "Normal", "CursorLine", "Pmenu", "StatusLine", "Folded", "NonText" }) do
    t.check("non-empty " .. group, next(hl(group)) ~= nil, "resolved empty")
  end

  -- termguicolors is required for a truecolour theme to mean anything.
  t.check("termguicolors on", vim.o.termguicolors == true, "off")

  -- Neovim 0.12 auto-detects `background` from the terminal via OSC 11, so
  -- a user on a light terminal arrives here with background=light. Little
  -- of our own highlighting reads it, but lualine's `auto` theme, several
  -- mini.nvim modules and a number of runtime syntax scripts do.
  vim.o.background = "light"
  vim.cmd.colorscheme("arrakis")
  t.check("forces background=dark", vim.o.background == "dark", tostring(vim.o.background))

  -- Review Focus 2: partial setup() must not drop other defaults, and a
  -- second call must not carry state over from the first.
  local arrakis = require("arrakis")
  arrakis.setup({ transparent = true })
  t.check("partial setup keeps default", arrakis.options.italic_comments == true, "italic_comments lost")
  t.check("partial setup applies key", arrakis.options.transparent == true, "transparent not set")
  arrakis.setup({ italic_comments = false })
  t.check("setup does not accumulate", arrakis.options.transparent == false, "transparent leaked from prior call")

  -- Review Focus 3: transparency must not leave an opaque seam.
  arrakis.setup({ transparent = true })
  vim.cmd.colorscheme("arrakis")
  for _, group in ipairs({ "Normal", "SignColumn", "WinBar" }) do
    t.check("transparent " .. group, hl(group).bg == nil, "kept a background")
  end

  -- TabLineFill is already transparent, so an opaque TabLine puts a solid
  -- block next to a see-through gap in the same row — the seam transparency
  -- exists to avoid. TabLineSel is a selection marker and keeps its
  -- background, the same way Visual and PmenuSel do.
  t.check("transparent TabLine", hl("TabLine").bg == nil, "kept a background")
  t.check("transparent TabLineFill", hl("TabLineFill").bg == nil, "kept a background")
  t.check("TabLineSel keeps its marker bg", hl("TabLineSel").bg ~= nil, "lost its background")

  -- Review Focus 4: an override naming a group the theme never sets must
  -- still be applied, not dropped.
  arrakis.setup({ overrides = { ArrakisNotARealGroup = { fg = p.spice } } })
  vim.cmd.colorscheme("arrakis")
  t.check(
    "override of unknown group",
    hex(hl("ArrakisNotARealGroup").fg) == p.spice,
    tostring(hex(hl("ArrakisNotARealGroup").fg))
  )

  -- An override of a group the theme DOES set must win.
  arrakis.setup({ overrides = { Normal = { fg = p.ember } } })
  vim.cmd.colorscheme("arrakis")
  t.check("override wins", hex(hl("Normal").fg) == p.ember, tostring(hex(hl("Normal").fg)))

  -- Leave a clean slate for any spec that runs after this one.
  arrakis.setup({})
  vim.cmd.colorscheme("arrakis")
end
