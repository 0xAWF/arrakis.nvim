-- Arrakis — every hex in the project lives here, exactly once.
-- Contrast ratios against bg are asserted by tests/contrast.lua.
return {
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

  -- Shared verbatim with extras/ghostty/arrakis. `ember` has no slot here;
  -- ANSI has no orange.
  ansi = {
    [0] = "#1a150f",
    [1] = "#d55d4f",
    [2] = "#8aa66b",
    [3] = "#d8a657",
    [4] = "#4fa8c5",
    [5] = "#b07ea8",
    [6] = "#5fa89b",
    [7] = "#bcab92",
    [8] = "#564a3c",
    [9] = "#e0705c",
    [10] = "#9dbb7c",
    [11] = "#e8bd6e",
    [12] = "#6fc0d8",
    [13] = "#c795bd",
    [14] = "#7cc4b6",
    [15] = "#f7ecd6",
  },
}
