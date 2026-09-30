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

  require("arrakis").setup({})
  vim.cmd.colorscheme("arrakis")

  local expected = {
    DiagnosticError = p.blood,
    DiagnosticWarn = p.spice,
    DiagnosticInfo = p.ibad,
    DiagnosticHint = p.scrub,
    DiagnosticOk = p.scrub,
    DiagnosticVirtualTextError = p.err_dim,
    DiagnosticVirtualTextWarn = p.warn_dim,
    DiagnosticVirtualTextInfo = p.info_dim,
    DiagnosticVirtualTextHint = p.hint_dim,
    DiffAdd = p.scrub,
    DiffChange = p.spice,
    DiffDelete = p.blood,
  }

  for group, want in pairs(expected) do
    t.check(
      "diagnostic " .. group,
      hex(hl(group).fg) == want,
      string.format("got %s, want %s", tostring(hex(hl(group).fg)), want)
    )
  end

  local underlines = {
    DiagnosticUnderlineError = p.blood,
    DiagnosticUnderlineWarn = p.spice,
    DiagnosticUnderlineInfo = p.ibad,
    DiagnosticUnderlineHint = p.scrub,
  }

  for group, want in pairs(underlines) do
    local got = hl(group)
    t.check("undercurl " .. group, got.undercurl == true, "not undercurl")
    t.check(
      "undercurl colour " .. group,
      hex(got.sp) == want,
      string.format("got %s, want %s", tostring(hex(got.sp)), want)
    )
  end
end
