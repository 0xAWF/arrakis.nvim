-- Arrakis — every hex in the project lives here, exactly once.
local p = {
  -- Base ramp, darkest to lightest
  bg = "#1a150f",
  bg_float = "#1e1812",
  bg_alt = "#231c15",
  bg_sel = "#2e261b",
  border = "#403629",
  linenr = "#564a3c",
  muted = "#746455",
  subtle = "#8f8170",
  fg_dim = "#bcab92",
  fg = "#e3d2b4",
  fg_bright = "#f7ecd6",

  -- Accents
  ember = "#c4643a", -- keywords
  spice = "#d8a657", -- strings, cursor, warnings
  ibad = "#4fa8c5", -- types, info
  num = "#bf9a5e", -- numbers, constants
  scrub = "#8aa66b", -- hints, git add
  water = "#5fa89b", -- ANSI cyan
  melange = "#b07ea8", -- ANSI magenta
  blood = "#d55d4f", -- errors

  -- Diagnostic virtual text: 45% accent over bg, hardcoded not blended
  err_dim = "#6e352c",
  warn_dim = "#6f572f",
  info_dim = "#325861",
  hint_dim = "#4c5738",
}

-- Shared verbatim with extras/ghostty/arrakis. Slots that are the same
-- colour as a named field reference it rather than repeating the hex, so
-- the two cannot drift apart; only the bright variants (9-14), which have
-- no named twin, are literals. `ember` has no slot here: ANSI has no orange.
p.ansi = {
  [0] = p.bg,
  [1] = p.blood,
  [2] = p.scrub,
  [3] = p.spice,
  [4] = p.ibad,
  [5] = p.melange,
  [6] = p.water,
  [7] = p.fg_dim,
  [8] = p.linenr,
  [9] = "#e0705c",
  [10] = "#9dbb7c",
  [11] = "#e8bd6e",
  [12] = "#6fc0d8",
  [13] = "#c795bd",
  [14] = "#7cc4b6",
  [15] = p.fg_bright,
}

return p
