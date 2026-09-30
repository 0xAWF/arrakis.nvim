-- Headless test runner. Run from the repository root:
--   nvim --headless -l tests/run.lua
vim.opt.runtimepath:prepend(vim.fn.getcwd())

local failures = {}
local total = 0

local t = {}

function t.check(name, ok, detail)
  total = total + 1
  if not ok then
    table.insert(failures, string.format("  %s — %s", name, detail or "failed"))
  end
end

local specs = { "contrast", "load", "syntax", "diagnostics", "plugins", "parity" }

for _, name in ipairs(specs) do
  local path = "tests/" .. name .. ".lua"
  local chunk = assert(loadfile(path), "cannot load " .. path)
  chunk()(t)
end

if #failures > 0 then
  io.stderr:write(string.format("\n%d/%d checks failed:\n", #failures, total))
  io.stderr:write(table.concat(failures, "\n") .. "\n")
  os.exit(1)
end

io.stdout:write(string.format("all %d checks passed\n", total))
os.exit(0)
