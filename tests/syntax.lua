local function hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

local function hex(n)
  if n == nil then
    return nil
  end
  return string.format("#%06x", n)
end

return function(t)
  local p = require("arrakis.palette")
  local arrakis = require("arrakis")

  arrakis.setup({})
  vim.cmd.colorscheme("arrakis")

  -- The restraint rule, asserted group by group.
  local expected = {
    ["Comment"] = p.muted,
    ["@comment"] = p.muted,
    ["Keyword"] = p.ember,
    ["@keyword"] = p.ember,
    ["@keyword.return"] = p.ember,
    ["@variable.builtin"] = p.ember,
    ["@string.escape"] = p.ember,
    ["String"] = p.spice,
    ["@string"] = p.spice,
    ["Type"] = p.ibad,
    ["@type"] = p.ibad,
    ["@type.builtin"] = p.ibad,
    ["Number"] = p.num,
    ["Boolean"] = p.num,
    ["Constant"] = p.num,
    ["@constant"] = p.num,
    ["Function"] = p.fg_bright,
    ["@function"] = p.fg_bright,
    ["@function.call"] = p.fg_bright,
    ["@variable"] = p.fg_dim,
    ["@property"] = p.fg_dim,
    ["@variable.parameter"] = p.fg_dim,
    ["@operator"] = p.subtle,
    ["@punctuation.bracket"] = p.subtle,
    ["Delimiter"] = p.subtle,
    ["@module"] = p.fg,
    ["@constructor"] = p.fg,
    ["@markup.raw"] = p.scrub,
    ["@comment.error"] = p.blood,
  }

  for group, want in pairs(expected) do
    t.check(
      "syntax " .. group,
      hex(hl(group).fg) == want,
      string.format("got %s, want %s", tostring(hex(hl(group).fg)), want)
    )
  end

  -- LSP semantic tokens are applied OVER treesitter. Unmapped, a server's
  -- defaults punch colour straight through the restraint rule, and the
  -- theme looks different per language. Each must be pinned.
  local lsp = {
    ["@lsp.type.class"] = p.ibad,
    ["@lsp.type.struct"] = p.ibad,
    ["@lsp.type.enum"] = p.ibad,
    ["@lsp.type.interface"] = p.ibad,
    ["@lsp.type.typeParameter"] = p.ibad,
    ["@lsp.type.function"] = p.fg_bright,
    ["@lsp.type.method"] = p.fg_bright,
    ["@lsp.type.variable"] = p.fg_dim,
    ["@lsp.type.property"] = p.fg_dim,
    ["@lsp.type.parameter"] = p.fg_dim,
    ["@lsp.type.keyword"] = p.ember,
    ["@lsp.type.string"] = p.spice,
    ["@lsp.type.number"] = p.num,
    ["@lsp.type.enumMember"] = p.num,
    ["@lsp.type.namespace"] = p.fg,
    ["@lsp.type.comment"] = p.muted,
  }

  for group, want in pairs(lsp) do
    t.check(
      "lsp " .. group,
      hex(hl(group).fg) == want,
      string.format("got %s, want %s", tostring(hex(hl(group).fg)), want)
    )
  end

  -- italic_comments, on by default and switchable.
  t.check("comments italic by default", hl("Comment").italic == true, "not italic")

  arrakis.setup({ italic_comments = false })
  vim.cmd.colorscheme("arrakis")
  t.check("comments not italic when off", hl("Comment").italic ~= true, "still italic")

  arrakis.setup({})
  vim.cmd.colorscheme("arrakis")
end
