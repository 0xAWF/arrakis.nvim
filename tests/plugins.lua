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
end
