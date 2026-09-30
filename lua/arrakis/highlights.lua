local palette = require("arrakis.palette")

-- Merge order is fixed: later modules may refine earlier ones, and user
-- overrides always land last.
local modules = { "editor", "syntax", "diagnostics", "plugins" }

local M = {}

function M.build(opts)
  local groups = {}

  for _, name in ipairs(modules) do
    for group, spec in pairs(require("arrakis.groups." .. name)(palette, opts)) do
      groups[group] = spec
    end
  end

  for group, spec in pairs(opts.overrides or {}) do
    groups[group] = spec
  end

  return groups
end

return M
