return function(p, _opts)
  return {
    DiagnosticError = { fg = p.blood },
    DiagnosticWarn = { fg = p.spice },
    DiagnosticInfo = { fg = p.ibad },
    DiagnosticHint = { fg = p.scrub },
    DiagnosticOk = { fg = p.scrub },

    DiagnosticSignError = { fg = p.blood },
    DiagnosticSignWarn = { fg = p.spice },
    DiagnosticSignInfo = { fg = p.ibad },
    DiagnosticSignHint = { fg = p.scrub },
    DiagnosticSignOk = { fg = p.scrub },

    -- Pre-dimmed, not blended at runtime. There are only four.
    DiagnosticVirtualTextError = { fg = p.err_dim },
    DiagnosticVirtualTextWarn = { fg = p.warn_dim },
    DiagnosticVirtualTextInfo = { fg = p.info_dim },
    DiagnosticVirtualTextHint = { fg = p.hint_dim },
    DiagnosticVirtualTextOk = { fg = p.hint_dim },

    DiagnosticUnderlineError = { sp = p.blood, undercurl = true },
    DiagnosticUnderlineWarn = { sp = p.spice, undercurl = true },
    DiagnosticUnderlineInfo = { sp = p.ibad, undercurl = true },
    DiagnosticUnderlineHint = { sp = p.scrub, undercurl = true },
    DiagnosticUnderlineOk = { sp = p.scrub, undercurl = true },

    DiagnosticDeprecated = { fg = p.muted, strikethrough = true },
    DiagnosticUnnecessary = { fg = p.muted },

    LspReferenceText = { bg = p.bg_sel },
    LspReferenceRead = { bg = p.bg_sel },
    LspReferenceWrite = { bg = p.bg_sel },
    LspInlayHint = { fg = p.linenr, bg = p.bg_alt },
    LspSignatureActiveParameter = { fg = p.spice, bold = true },
    LspCodeLens = { fg = p.muted },

    -- Needed for :diffthis regardless of which git plugin is installed.
    DiffAdd = { fg = p.scrub, bg = p.bg_alt },
    DiffChange = { fg = p.spice, bg = p.bg_alt },
    DiffDelete = { fg = p.blood, bg = p.bg_alt },
    DiffText = { fg = p.spice, bg = p.bg_sel },

    Added = { fg = p.scrub },
    Changed = { fg = p.spice },
    Removed = { fg = p.blood },

    GitSignsAdd = { fg = p.scrub },
    GitSignsChange = { fg = p.spice },
    GitSignsDelete = { fg = p.blood },
    GitSignsAddLn = { bg = p.bg_alt },
    GitSignsChangeLn = { bg = p.bg_alt },
    GitSignsDeleteLn = { bg = p.bg_alt },
    GitSignsCurrentLineBlame = { fg = p.linenr, italic = true },
  }
end
