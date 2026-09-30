local function hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

return function(t)
  require("arrakis").setup({})
  vim.cmd.colorscheme("arrakis")

  -- These are the groups a user would notice missing first in each plugin.
  local groups = {
    -- oil.nvim
    "OilDir",
    "OilFile",
    "OilCreate",
    "OilDelete",
    "OilPermissionRead",
    "OilPermissionWrite",
    "OilPermissionExecute",
    -- telescope.nvim
    "TelescopeNormal",
    "TelescopeBorder",
    "TelescopeTitle",
    "TelescopePromptPrefix",
    "TelescopeSelection",
    "TelescopeMatching",
    -- blink.cmp
    "BlinkCmpMenu",
    "BlinkCmpMenuBorder",
    "BlinkCmpMenuSelection",
    "BlinkCmpLabel",
    "BlinkCmpLabelMatch",
    "BlinkCmpKind",
    "BlinkCmpDoc",
    "BlinkCmpDocBorder",
    -- trouble.nvim
    "TroubleNormal",
    "TroubleText",
    "TroubleCount",
    -- toggleterm.nvim
    "ToggleTerm1FloatBorder",
    -- mini.nvim
    "MiniStatuslineModeNormal",
    "MiniStatuslineModeInsert",
    "MiniSurround",
    "MiniIconsAzure",
  }

  for _, group in ipairs(groups) do
    t.check("plugin group " .. group, next(hl(group)) ~= nil, "resolved empty")
  end

  -- Under `transparent`, the theme's own NormalFloat goes NONE. A plugin
  -- float that keeps bg_float then renders as an opaque panel floating over
  -- a transparent editor — the inconsistency is more jarring than either
  -- choice alone. Selection rows (PmenuSel and friends) still keep theirs.
  require("arrakis").setup({ transparent = true })
  vim.cmd.colorscheme("arrakis")

  local floats = {
    "TelescopeNormal",
    "TelescopeBorder",
    "TelescopePreviewNormal",
    "BlinkCmpMenu",
    "BlinkCmpMenuBorder",
    "BlinkCmpDoc",
    "BlinkCmpDocBorder",
    "TroubleNormal",
    "ToggleTermNormal",
    "ToggleTerm1FloatBorder",
  }

  for _, group in ipairs(floats) do
    t.check("transparent " .. group, hl(group).bg == nil, "kept a background")
  end

  t.check("TelescopeSelection keeps its marker bg", hl("TelescopeSelection").bg ~= nil, "lost its background")
  t.check("BlinkCmpMenuSelection keeps its marker bg", hl("BlinkCmpMenuSelection").bg ~= nil, "lost its background")

  require("arrakis").setup({})
  vim.cmd.colorscheme("arrakis")
end
