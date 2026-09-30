local M = {}

local defaults = {
  transparent = false,
  italic_comments = true,
  overrides = {},
}

M.options = vim.deepcopy(defaults)

-- Each call resolves against a fresh copy of the defaults, so options never
-- accumulate across calls.
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})
end

function M.load()
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  -- Before colors_name is set: assigning `background` while g:colors_name
  -- is set re-sources the colorscheme, which would recurse.
  vim.o.background = "dark"
  -- Set after `highlight clear`, which wipes it.
  vim.g.colors_name = "arrakis"

  for group, spec in pairs(require("arrakis.highlights").build(M.options)) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  require("arrakis.groups.terminal")(require("arrakis.palette"))
end

return M
