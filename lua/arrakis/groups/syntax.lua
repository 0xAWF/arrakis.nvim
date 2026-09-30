return function(p, opts)
  local comment = { fg = p.muted, italic = opts.italic_comments }

  local groups = {
    -- Legacy vim syntax groups, still used by non-treesitter filetypes
    Comment = comment,
    Keyword = { fg = p.ember },
    Statement = { fg = p.ember },
    Conditional = { fg = p.ember },
    Repeat = { fg = p.ember },
    Exception = { fg = p.ember },
    Include = { fg = p.ember },
    PreProc = { fg = p.ember },
    Define = { fg = p.ember },
    Macro = { fg = p.ember },
    String = { fg = p.spice },
    Character = { fg = p.spice },
    Type = { fg = p.ibad },
    StorageClass = { fg = p.ibad },
    Structure = { fg = p.ibad },
    Typedef = { fg = p.ibad },
    Number = { fg = p.num },
    Float = { fg = p.num },
    Boolean = { fg = p.num },
    Constant = { fg = p.num },
    Function = { fg = p.fg_bright },
    Identifier = { fg = p.fg_dim },
    Operator = { fg = p.subtle },
    Delimiter = { fg = p.subtle },
    Special = { fg = p.ember },
    SpecialChar = { fg = p.ember },
    Todo = { fg = p.ibad, bold = true },
    Error = { fg = p.blood },
    Underlined = { fg = p.ibad, underline = true },

    -- Treesitter: hue only where it says something a name cannot
    ["@comment"] = comment,
    ["@keyword"] = { fg = p.ember },
    ["@keyword.function"] = { fg = p.ember },
    ["@keyword.return"] = { fg = p.ember },
    ["@keyword.operator"] = { fg = p.ember },
    ["@keyword.conditional"] = { fg = p.ember },
    ["@keyword.repeat"] = { fg = p.ember },
    ["@keyword.exception"] = { fg = p.ember },
    ["@keyword.import"] = { fg = p.ember },
    ["@keyword.directive"] = { fg = p.ember },
    ["@conditional"] = { fg = p.ember },
    ["@repeat"] = { fg = p.ember },
    ["@include"] = { fg = p.ember },
    ["@exception"] = { fg = p.ember },
    -- self/this read as keywords, not as variables
    ["@variable.builtin"] = { fg = p.ember },
    ["@string.escape"] = { fg = p.ember },
    ["@string.special"] = { fg = p.ember },
    ["@character.special"] = { fg = p.ember },

    ["@string"] = { fg = p.spice },
    ["@string.documentation"] = { fg = p.spice },
    ["@character"] = { fg = p.spice },

    ["@type"] = { fg = p.ibad },
    ["@type.builtin"] = { fg = p.ibad },
    ["@type.definition"] = { fg = p.ibad },
    ["@type.qualifier"] = { fg = p.ibad },
    ["@attribute"] = { fg = p.ibad },

    ["@constant"] = { fg = p.num },
    ["@constant.builtin"] = { fg = p.num },
    ["@constant.macro"] = { fg = p.num },
    ["@number"] = { fg = p.num },
    ["@number.float"] = { fg = p.num },
    ["@float"] = { fg = p.num },
    ["@boolean"] = { fg = p.num },

    -- Functions are lifted in brightness, not in hue
    ["@function"] = { fg = p.fg_bright },
    ["@function.call"] = { fg = p.fg_bright },
    ["@function.builtin"] = { fg = p.fg_bright },
    ["@function.macro"] = { fg = p.fg_bright },
    ["@function.method"] = { fg = p.fg_bright },
    ["@function.method.call"] = { fg = p.fg_bright },
    ["@method"] = { fg = p.fg_bright },
    ["@method.call"] = { fg = p.fg_bright },

    -- Names carry their own meaning; they stay on the sand ramp
    ["@variable"] = { fg = p.fg_dim },
    ["@variable.parameter"] = { fg = p.fg_dim },
    ["@variable.member"] = { fg = p.fg_dim },
    ["@parameter"] = { fg = p.fg_dim },
    ["@property"] = { fg = p.fg_dim },
    ["@field"] = { fg = p.fg_dim },

    ["@operator"] = { fg = p.subtle },
    ["@punctuation"] = { fg = p.subtle },
    ["@punctuation.delimiter"] = { fg = p.subtle },
    ["@punctuation.bracket"] = { fg = p.subtle },
    ["@punctuation.special"] = { fg = p.subtle },

    ["@constructor"] = { fg = p.fg },
    ["@module"] = { fg = p.fg },
    ["@namespace"] = { fg = p.fg },
    ["@label"] = { fg = p.fg },

    ["@tag"] = { fg = p.ember },
    ["@tag.builtin"] = { fg = p.ember },
    ["@tag.attribute"] = { fg = p.fg_dim },
    ["@tag.delimiter"] = { fg = p.subtle },

    ["@markup.heading"] = { fg = p.spice, bold = true },
    ["@markup.strong"] = { fg = p.fg_bright, bold = true },
    ["@markup.italic"] = { fg = p.fg, italic = true },
    ["@markup.strikethrough"] = { fg = p.muted, strikethrough = true },
    ["@markup.link"] = { fg = p.ibad, underline = true },
    ["@markup.link.url"] = { fg = p.ibad, underline = true },
    ["@markup.link.label"] = { fg = p.ibad },
    ["@markup.raw"] = { fg = p.scrub },
    ["@markup.raw.block"] = { fg = p.scrub },
    ["@markup.list"] = { fg = p.ember },
    ["@markup.quote"] = { fg = p.muted, italic = true },

    ["@comment.todo"] = { fg = p.ibad, bold = true },
    ["@comment.note"] = { fg = p.ibad, bold = true },
    ["@comment.warning"] = { fg = p.spice, bold = true },
    ["@comment.error"] = { fg = p.blood, bold = true },

    ["@diff.plus"] = { fg = p.scrub },
    ["@diff.minus"] = { fg = p.blood },
    ["@diff.delta"] = { fg = p.spice },
  }

  -- LSP semantic tokens are layered over treesitter. Pin each to its
  -- treesitter twin, or a server's defaults show through and the theme
  -- stops being the same theme in every language.
  local semantic = {
    ["@lsp.type.class"] = p.ibad,
    ["@lsp.type.struct"] = p.ibad,
    ["@lsp.type.enum"] = p.ibad,
    ["@lsp.type.interface"] = p.ibad,
    ["@lsp.type.type"] = p.ibad,
    ["@lsp.type.typeParameter"] = p.ibad,
    ["@lsp.type.decorator"] = p.ibad,
    ["@lsp.type.function"] = p.fg_bright,
    ["@lsp.type.method"] = p.fg_bright,
    ["@lsp.type.variable"] = p.fg_dim,
    ["@lsp.type.property"] = p.fg_dim,
    ["@lsp.type.parameter"] = p.fg_dim,
    ["@lsp.type.keyword"] = p.ember,
    ["@lsp.type.modifier"] = p.ember,
    ["@lsp.type.string"] = p.spice,
    ["@lsp.type.number"] = p.num,
    ["@lsp.type.enumMember"] = p.num,
    ["@lsp.type.namespace"] = p.fg,
    ["@lsp.type.comment"] = p.muted,
    ["@lsp.type.operator"] = p.subtle,
  }

  for group, colour in pairs(semantic) do
    groups[group] = { fg = colour }
  end

  return groups
end
