return function(p, opts)
  -- Under `transparent`, anything that spans the full window width must
  -- drop its background or it shows as an opaque seam.
  local bg = opts.transparent and "NONE" or p.bg
  local bg_float = opts.transparent and "NONE" or p.bg_float

  return {
    Normal = { fg = p.fg, bg = bg },
    NormalNC = { fg = p.fg, bg = bg },
    NormalFloat = { fg = p.fg, bg = bg_float },
    FloatBorder = { fg = p.border, bg = bg_float },
    FloatTitle = { fg = p.spice, bg = bg_float, bold = true },
    WinSeparator = { fg = p.border, bg = bg },
    EndOfBuffer = { fg = p.bg, bg = bg },

    CursorLine = { bg = p.bg_alt },
    CursorColumn = { bg = p.bg_alt },
    CursorLineNr = { fg = p.spice, bold = true },
    LineNr = { fg = p.linenr },
    SignColumn = { bg = bg },
    FoldColumn = { fg = p.linenr, bg = bg },
    -- colorcolumn is on screen constantly, so it sits below CursorLine in
    -- visual weight rather than above it.
    ColorColumn = { bg = p.bg_alt },
    Folded = { fg = p.muted, bg = p.bg_alt },
    Conceal = { fg = p.muted },

    Visual = { bg = p.bg_sel },
    VisualNOS = { bg = p.bg_sel },
    Search = { fg = p.fg, bg = p.bg_sel },
    IncSearch = { fg = p.bg, bg = p.spice },
    CurSearch = { fg = p.bg, bg = p.spice },
    MatchParen = { fg = p.spice, underline = true },
    QuickFixLine = { bg = p.bg_sel },

    Pmenu = { fg = p.fg_dim, bg = p.bg_float },
    PmenuSel = { fg = p.fg_bright, bg = p.bg_sel },
    PmenuSbar = { bg = p.bg_float },
    PmenuThumb = { bg = p.border },

    StatusLine = { fg = p.fg_dim, bg = p.bg_alt },
    StatusLineNC = { fg = p.muted, bg = p.bg_alt },
    TabLine = { fg = p.muted, bg = p.bg_alt },
    TabLineSel = { fg = p.fg_bright, bg = p.bg_sel },
    TabLineFill = { bg = bg },
    WinBar = { fg = p.fg_dim, bg = bg },
    WinBarNC = { fg = p.muted, bg = bg },

    Cursor = { fg = p.bg, bg = p.spice },
    lCursor = { fg = p.bg, bg = p.spice },
    TermCursor = { fg = p.bg, bg = p.spice },

    NonText = { fg = p.linenr },
    Whitespace = { fg = p.linenr },
    SpecialKey = { fg = p.linenr },
    Directory = { fg = p.ibad },
    Title = { fg = p.spice, bold = true },

    ErrorMsg = { fg = p.blood },
    WarningMsg = { fg = p.spice },
    ModeMsg = { fg = p.fg_dim, bold = true },
    MsgArea = { fg = p.fg_dim },
    MoreMsg = { fg = p.scrub },
    Question = { fg = p.scrub },

    SpellBad = { sp = p.blood, undercurl = true },
    SpellCap = { sp = p.spice, undercurl = true },
    SpellLocal = { sp = p.ibad, undercurl = true },
    SpellRare = { sp = p.melange, undercurl = true },
  }
end
