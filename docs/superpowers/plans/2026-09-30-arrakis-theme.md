# Arrakis Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a dark, Dune-inspired colorscheme as a publishable Neovim plugin plus a hand-matched Ghostty theme, verified by a dependency-free headless test suite.

**Architecture:** `lua/arrakis/palette.lua` holds every hex once. Five `groups/*.lua` modules each export `function(palette, opts) -> table` and are merged by `highlights.lua`, with user `overrides` applied last. `colors/arrakis.lua` calls `require("arrakis").load()`. The Ghostty theme is a hand-written twin; a read-only parity test fails if the two drift.

**Tech Stack:** Lua 5.1 (LuaJIT, as embedded in Neovim ≥ 0.10). No test framework, no runtime dependencies, no build step. Tests run under `nvim --headless -l`.

**Spec:** `docs/superpowers/specs/2026-09-30-arrakis-theme-design.md`

## Global Constraints

- **Dark only.** No light variant, no `vim.o.background` branching anywhere.
- **The restraint rule decides ambiguity:** a token gets a hue only if the hue tells you something its name cannot. Names, fields, parameters and punctuation stay on the sand ramp.
- **Every hex lives in `lua/arrakis/palette.lua` exactly once.** No literal hex string may appear in any `groups/*.lua`, in `highlights.lua`, or in `init.lua`. The only hexes outside `palette.lua` are in `extras/ghostty/arrakis` (the hand-maintained twin) and in test fixtures.
- **No generation step.** No task may write a script that emits `extras/ghostty/arrakis`.
- **No new dependencies**, runtime or dev. Tests use only what ships inside Neovim.
- **Neovim floor: 0.10.** `vim.api.nvim_set_hl`, `vim.deepcopy`, `vim.tbl_deep_extend` are available; nothing newer may be used.
- **Group modules are pure.** A `groups/*.lua` module returns a table and must not call `nvim_set_hl`, read `vim.g`, or touch global state. `groups/terminal.lua` is the single exception and is applied separately by `load()`.
- **Commit messages are short and imperative.** No co-author trailers.
- Run all test commands **from the repository root**; `tests/run.lua` resolves paths relative to the working directory.

## Review Focus

Five failure modes the spec implies but that no task's happy-path tests would otherwise exercise. Each has a test assigned to the task owning the code.

1. **Reloading the colorscheme.** `:colorscheme arrakis` twice in one session — `hi clear` wipes `g:colors_name`, and a theme that reads it back carelessly errors on the second load. Test in Task 2.
2. **Partial `setup()` options.** `setup({ transparent = true })` must not silently drop `italic_comments`, and a second `setup()` call must not accumulate state from the first. Test in Task 2.
3. **`transparent = true` leaving an opaque seam.** `SignColumn`, `FloatBorder` and `WinBar` are the groups that visibly break transparency if they keep a background. Test in Task 2.
4. **`overrides` naming an otherwise-undefined group.** A user overriding a group the theme never sets (e.g. a plugin we don't theme) must still get it applied, not dropped. Test in Task 2.
5. **Ghostty file drifting in format, not just value.** The parity test must survive the legal variations Ghostty accepts — `palette = 0=#1a150f` with arbitrary surrounding whitespace, and uppercase hex — so that a reformat doesn't read as a drift and a real drift doesn't read as a format quirk. Test in Task 6.

---

### Task 1: Palette and the test harness

**Files:**
- Create: `lua/arrakis/palette.lua`
- Create: `tests/run.lua`
- Create: `tests/contrast.lua`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `require("arrakis.palette")` → flat table of string fields: `bg`, `bg_float`, `bg_alt`, `bg_sel`, `border`, `linenr`, `muted`, `subtle`, `fg_dim`, `fg`, `fg_bright`, `ember`, `spice`, `ibad`, `num`, `scrub`, `water`, `melange`, `blood`, `err_dim`, `warn_dim`, `info_dim`, `hint_dim`, each a `"#rrggbb"` string; plus `ansi`, a table keyed `[0]` through `[15]` of the same string form.
  - `tests/run.lua` — the runner. Each spec file is `tests/<name>.lua` returning `function(t)` where `t.check(name, ok, detail)` records a result. Add new spec names to the `specs` list in `run.lua`.

- [ ] **Step 1: Write the failing test**

Create `tests/run.lua`:

```lua
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

local specs = { "contrast" }

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
```

Create `tests/contrast.lua`:

```lua
-- WCAG 2.1 relative luminance and contrast ratio, computed in plain Lua.
local function channel(byte)
  local c = byte / 255
  if c <= 0.04045 then
    return c / 12.92
  end
  return ((c + 0.055) / 1.055) ^ 2.4
end

local function luminance(hex)
  local r, g, b = hex:match("^#(%x%x)(%x%x)(%x%x)$")
  if not r then
    error("malformed hex: " .. tostring(hex))
  end
  return 0.2126 * channel(tonumber(r, 16))
    + 0.7152 * channel(tonumber(g, 16))
    + 0.0722 * channel(tonumber(b, 16))
end

local function ratio(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

-- Thresholds from the spec. Comments and chrome sit below the text bar by
-- design, so they get their own lower bars rather than being exempted.
local thresholds = {
  fg_bright = 7,
  fg = 7,
  fg_dim = 7,
  ember = 4.5,
  spice = 4.5,
  ibad = 4.5,
  num = 4.5,
  scrub = 4.5,
  water = 4.5,
  melange = 4.5,
  blood = 4.5,
  subtle = 4.5,
  muted = 3,
  linenr = 2,
  border = 1.5,
}

return function(t)
  local p = require("arrakis.palette")

  -- Every value in the palette must be a well-formed hex string.
  for name, value in pairs(p) do
    if name ~= "ansi" then
      t.check(
        "hex format " .. name,
        type(value) == "string" and value:match("^#%x%x%x%x%x%x$") ~= nil,
        string.format("got %s", tostring(value))
      )
    end
  end

  for i = 0, 15 do
    t.check(
      string.format("hex format ansi[%d]", i),
      type(p.ansi[i]) == "string" and p.ansi[i]:match("^#%x%x%x%x%x%x$") ~= nil,
      string.format("got %s", tostring(p.ansi[i]))
    )
  end

  for name, minimum in pairs(thresholds) do
    local got = ratio(p[name], p.bg)
    t.check(
      "contrast " .. name,
      got >= minimum,
      string.format("%.2f:1 against bg, need %.2f:1", got, minimum)
    )
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nvim --headless -l tests/run.lua`
Expected: FAIL — the runner aborts with `module 'arrakis.palette' not found`, because `lua/arrakis/palette.lua` does not exist yet.

- [ ] **Step 3: Write minimal implementation**

Create `lua/arrakis/palette.lua`:

```lua
-- Arrakis — every hex in the project lives here, exactly once.
-- Contrast ratios against bg are asserted by tests/contrast.lua.
return {
  -- Base ramp, darkest to lightest
  bg = "#1a150f",
  bg_float = "#1e1812",
  bg_alt = "#231c15",
  bg_sel = "#2e261b",
  border = "#403629",
  linenr = "#564a3c",
  muted = "#746455",
  subtle = "#8f8170",
  fg_dim = "#bcab92",
  fg = "#e3d2b4",
  fg_bright = "#f7ecd6",

  -- Accents
  ember = "#c4643a", -- keywords
  spice = "#d8a657", -- strings, cursor, warnings
  ibad = "#4fa8c5", -- types, info
  num = "#bf9a5e", -- numbers, constants
  scrub = "#8aa66b", -- hints, git add
  water = "#5fa89b", -- ANSI cyan
  melange = "#b07ea8", -- ANSI magenta
  blood = "#d1554a", -- errors

  -- Diagnostic virtual text: 45% accent over bg, hardcoded not blended
  err_dim = "#6c3229",
  warn_dim = "#6f572f",
  info_dim = "#325861",
  hint_dim = "#4c5738",

  -- Shared verbatim with extras/ghostty/arrakis. `ember` has no slot here;
  -- ANSI has no orange.
  ansi = {
    [0] = "#1a150f",
    [1] = "#d1554a",
    [2] = "#8aa66b",
    [3] = "#d8a657",
    [4] = "#4fa8c5",
    [5] = "#b07ea8",
    [6] = "#5fa89b",
    [7] = "#bcab92",
    [8] = "#564a3c",
    [9] = "#e0705c",
    [10] = "#9dbb7c",
    [11] = "#e8bd6e",
    [12] = "#6fc0d8",
    [13] = "#c795bd",
    [14] = "#7cc4b6",
    [15] = "#f7ecd6",
  },
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nvim --headless -l tests/run.lua`
Expected: PASS — `all 54 checks passed` (23 palette hex-format checks, 16 ANSI hex-format checks, 15 contrast checks).

- [ ] **Step 5: Commit**

```bash
git add lua/arrakis/palette.lua tests/run.lua tests/contrast.lua
git commit -m "Add palette and contrast test harness"
```

---

### Task 2: Loader, editor chrome, and setup options

**Files:**
- Create: `lua/arrakis/init.lua`
- Create: `lua/arrakis/highlights.lua`
- Create: `lua/arrakis/groups/editor.lua`
- Create: `colors/arrakis.lua`
- Create: `tests/load.lua`
- Modify: `tests/run.lua` (add `"load"` to the `specs` list)

**Interfaces:**
- Consumes: `require("arrakis.palette")` from Task 1.
- Produces:
  - `require("arrakis").setup(opts)` — stores options; `opts` may be `nil` or partial. Keys: `transparent` (boolean, default `false`), `italic_comments` (boolean, default `true`), `overrides` (table of `group -> nvim_set_hl spec`, default `{}`).
  - `require("arrakis").load()` — applies the colorscheme. Idempotent; safe to call repeatedly.
  - `require("arrakis").options` — the resolved option table.
  - `require("arrakis.highlights").build(opts)` → flat `{ [group] = spec }` table.
  - `require("arrakis.groups.editor")(palette, opts)` → flat group table. Every later group module has this exact signature.

- [ ] **Step 1: Write the failing test**

Create `tests/load.lua`:

```lua
-- Resolve a highlight group to a concrete definition.
local function hl(group)
  return vim.api.nvim_get_hl(0, { name = group, link = false })
end

-- nvim_get_hl returns colours as integers; compare against palette hex.
local function hex(n)
  if n == nil then
    return nil
  end
  return string.format("#%06x", n)
end

return function(t)
  local p = require("arrakis.palette")

  -- Loading must not error, and must set colors_name.
  local ok, err = pcall(vim.cmd.colorscheme, "arrakis")
  t.check("colorscheme loads", ok, tostring(err))
  t.check("colors_name set", vim.g.colors_name == "arrakis", tostring(vim.g.colors_name))

  -- Review Focus 1: reloading. `hi clear` wipes colors_name mid-load; a
  -- second load must not error or leave the scheme half-applied.
  local ok2, err2 = pcall(vim.cmd.colorscheme, "arrakis")
  t.check("colorscheme reloads", ok2, tostring(err2))
  t.check("colors_name after reload", vim.g.colors_name == "arrakis", tostring(vim.g.colors_name))

  -- Core chrome resolves to the palette, not to nothing.
  t.check("Normal fg", hex(hl("Normal").fg) == p.fg, tostring(hex(hl("Normal").fg)))
  t.check("Normal bg", hex(hl("Normal").bg) == p.bg, tostring(hex(hl("Normal").bg)))
  t.check("CursorLine bg", hex(hl("CursorLine").bg) == p.bg_alt, tostring(hex(hl("CursorLine").bg)))
  t.check("CursorLineNr fg", hex(hl("CursorLineNr").fg) == p.spice, tostring(hex(hl("CursorLineNr").fg)))
  t.check("LineNr fg", hex(hl("LineNr").fg) == p.linenr, tostring(hex(hl("LineNr").fg)))
  t.check("ColorColumn bg", hex(hl("ColorColumn").bg) == p.bg_alt, tostring(hex(hl("ColorColumn").bg)))
  t.check("Visual bg", hex(hl("Visual").bg) == p.bg_sel, tostring(hex(hl("Visual").bg)))
  t.check("NormalFloat bg", hex(hl("NormalFloat").bg) == p.bg_float, tostring(hex(hl("NormalFloat").bg)))
  t.check("FloatBorder fg", hex(hl("FloatBorder").fg) == p.border, tostring(hex(hl("FloatBorder").fg)))

  -- No group may resolve to an empty definition.
  for _, group in ipairs({ "Normal", "CursorLine", "Pmenu", "StatusLine", "Folded", "NonText" }) do
    t.check("non-empty " .. group, next(hl(group)) ~= nil, "resolved empty")
  end

  -- termguicolors is required for a truecolour theme to mean anything.
  t.check("termguicolors on", vim.o.termguicolors == true, "off")

  -- Review Focus 2: partial setup() must not drop other defaults, and a
  -- second call must not carry state over from the first.
  local arrakis = require("arrakis")
  arrakis.setup({ transparent = true })
  t.check("partial setup keeps default", arrakis.options.italic_comments == true, "italic_comments lost")
  t.check("partial setup applies key", arrakis.options.transparent == true, "transparent not set")
  arrakis.setup({ italic_comments = false })
  t.check("setup does not accumulate", arrakis.options.transparent == false, "transparent leaked from prior call")

  -- Review Focus 3: transparency must not leave an opaque seam.
  arrakis.setup({ transparent = true })
  vim.cmd.colorscheme("arrakis")
  for _, group in ipairs({ "Normal", "SignColumn", "WinBar" }) do
    t.check("transparent " .. group, hl(group).bg == nil, "kept a background")
  end

  -- Review Focus 4: an override naming a group the theme never sets must
  -- still be applied, not dropped.
  arrakis.setup({ overrides = { ArrakisNotARealGroup = { fg = p.spice } } })
  vim.cmd.colorscheme("arrakis")
  t.check(
    "override of unknown group",
    hex(hl("ArrakisNotARealGroup").fg) == p.spice,
    tostring(hex(hl("ArrakisNotARealGroup").fg))
  )

  -- An override of a group the theme DOES set must win.
  arrakis.setup({ overrides = { Normal = { fg = p.ember } } })
  vim.cmd.colorscheme("arrakis")
  t.check("override wins", hex(hl("Normal").fg) == p.ember, tostring(hex(hl("Normal").fg)))

  -- Leave a clean slate for any spec that runs after this one.
  arrakis.setup({})
  vim.cmd.colorscheme("arrakis")
end
```

Modify `tests/run.lua` — change the `specs` line to:

```lua
local specs = { "contrast", "load" }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nvim --headless -l tests/run.lua`
Expected: FAIL — `colorscheme loads` fails with `Cannot find color scheme 'arrakis'`, and the checks after it fail on empty highlight definitions.

- [ ] **Step 3: Write minimal implementation**

Create `lua/arrakis/groups/editor.lua`:

```lua
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
```

Create `lua/arrakis/highlights.lua`:

```lua
local palette = require("arrakis.palette")

-- Merge order is fixed: later modules may refine earlier ones, and user
-- overrides always land last.
local modules = { "editor" }

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
```

Create `lua/arrakis/init.lua`:

```lua
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
  -- Set after `highlight clear`, which wipes it.
  vim.g.colors_name = "arrakis"

  for group, spec in pairs(require("arrakis.highlights").build(M.options)) do
    vim.api.nvim_set_hl(0, group, spec)
  end
end

return M
```

Create `colors/arrakis.lua`:

```lua
require("arrakis").load()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nvim --headless -l tests/run.lua`
Expected: PASS, zero failures.

- [ ] **Step 5: Commit**

```bash
git add lua/arrakis/init.lua lua/arrakis/highlights.lua lua/arrakis/groups/editor.lua colors/arrakis.lua tests/load.lua tests/run.lua
git commit -m "Add loader, editor chrome and setup options"
```

---

### Task 3: Syntax groups and LSP semantic tokens

**Files:**
- Create: `lua/arrakis/groups/syntax.lua`
- Create: `tests/syntax.lua`
- Modify: `lua/arrakis/highlights.lua` (add `"syntax"` to `modules`)
- Modify: `tests/run.lua` (add `"syntax"` to `specs`)

**Interfaces:**
- Consumes: `require("arrakis.palette")`, and the `function(palette, opts) -> table` module contract from Task 2.
- Produces: no new public API. Adds treesitter capture groups and `@lsp.type.*` / `@lsp.mod.*` groups to the merged table.

- [ ] **Step 1: Write the failing test**

Create `tests/syntax.lua`:

```lua
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
```

Modify `tests/run.lua` — change the `specs` line to:

```lua
local specs = { "contrast", "load", "syntax" }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nvim --headless -l tests/run.lua`
Expected: FAIL — every `syntax @...` and `lsp @...` check fails with `got nil`, because no syntax module is merged yet.

- [ ] **Step 3: Write minimal implementation**

Create `lua/arrakis/groups/syntax.lua`:

```lua
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
```

Modify `lua/arrakis/highlights.lua` — change the `modules` line to:

```lua
local modules = { "editor", "syntax" }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nvim --headless -l tests/run.lua`
Expected: PASS, zero failures.

- [ ] **Step 5: Commit**

```bash
git add lua/arrakis/groups/syntax.lua lua/arrakis/highlights.lua tests/syntax.lua tests/run.lua
git commit -m "Add syntax and LSP semantic token groups"
```

---

### Task 4: Diagnostics, git and diff

**Files:**
- Create: `lua/arrakis/groups/diagnostics.lua`
- Create: `tests/diagnostics.lua`
- Modify: `lua/arrakis/highlights.lua` (add `"diagnostics"` to `modules`)
- Modify: `tests/run.lua` (add `"diagnostics"` to `specs`)

**Interfaces:**
- Consumes: `require("arrakis.palette")`, the module contract from Task 2.
- Produces: no new public API.

- [ ] **Step 1: Write the failing test**

Create `tests/diagnostics.lua`:

```lua
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

  -- Underlines must be undercurl in the matching accent, carried on `sp`.
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
```

Modify `tests/run.lua` — change the `specs` line to:

```lua
local specs = { "contrast", "load", "syntax", "diagnostics" }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nvim --headless -l tests/run.lua`
Expected: FAIL — `diagnostic DiagnosticError` and the rest fail with `got nil`.

- [ ] **Step 3: Write minimal implementation**

Create `lua/arrakis/groups/diagnostics.lua`:

```lua
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
```

Modify `lua/arrakis/highlights.lua` — change the `modules` line to:

```lua
local modules = { "editor", "syntax", "diagnostics" }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nvim --headless -l tests/run.lua`
Expected: PASS, zero failures.

- [ ] **Step 5: Commit**

```bash
git add lua/arrakis/groups/diagnostics.lua lua/arrakis/highlights.lua tests/diagnostics.lua tests/run.lua
git commit -m "Add diagnostic, git and diff groups"
```

---

### Task 5: Plugin groups

**Files:**
- Create: `lua/arrakis/groups/plugins.lua`
- Create: `tests/plugins.lua`
- Modify: `lua/arrakis/highlights.lua` (add `"plugins"` to `modules`)
- Modify: `tests/run.lua` (add `"plugins"` to `specs`)

**Interfaces:**
- Consumes: `require("arrakis.palette")`, the module contract from Task 2.
- Produces: no new public API.

Themed plugins are exactly: oil.nvim, telescope.nvim, blink.cmp, trouble.nvim, toggleterm.nvim, mini.nvim. Gitsigns was already covered in Task 4 alongside the `Diff*` groups. No other plugin is themed.

- [ ] **Step 1: Write the failing test**

Create `tests/plugins.lua`:

```lua
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
```

Modify `tests/run.lua` — change the `specs` line to:

```lua
local specs = { "contrast", "load", "syntax", "diagnostics", "plugins" }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nvim --headless -l tests/run.lua`
Expected: FAIL — every `plugin group ...` check fails with `resolved empty`.

- [ ] **Step 3: Write minimal implementation**

Create `lua/arrakis/groups/plugins.lua`:

```lua
return function(p, _opts)
  return {
    -- oil.nvim
    OilDir = { fg = p.ibad },
    OilDirIcon = { fg = p.ibad },
    OilFile = { fg = p.fg },
    OilLink = { fg = p.water, underline = true },
    OilLinkTarget = { fg = p.water },
    OilCreate = { fg = p.scrub },
    OilDelete = { fg = p.blood },
    OilMove = { fg = p.spice },
    OilCopy = { fg = p.ibad },
    OilChange = { fg = p.spice },
    OilRestore = { fg = p.scrub },
    OilPurge = { fg = p.blood },
    OilTrash = { fg = p.blood },
    OilSize = { fg = p.muted },
    OilMtime = { fg = p.muted },
    OilPermissionNone = { fg = p.linenr },
    OilPermissionRead = { fg = p.spice },
    OilPermissionWrite = { fg = p.ember },
    OilPermissionExecute = { fg = p.scrub },
    OilTypeDir = { fg = p.ibad },
    OilTypeFile = { fg = p.fg_dim },
    OilTypeLink = { fg = p.water },

    -- telescope.nvim
    TelescopeNormal = { fg = p.fg, bg = p.bg_float },
    TelescopeBorder = { fg = p.border, bg = p.bg_float },
    TelescopeTitle = { fg = p.bg, bg = p.spice, bold = true },
    TelescopePromptNormal = { fg = p.fg, bg = p.bg_alt },
    TelescopePromptBorder = { fg = p.border, bg = p.bg_alt },
    TelescopePromptTitle = { fg = p.bg, bg = p.ember, bold = true },
    TelescopePromptPrefix = { fg = p.spice },
    TelescopePromptCounter = { fg = p.muted },
    TelescopeResultsNormal = { fg = p.fg_dim, bg = p.bg_float },
    TelescopeResultsBorder = { fg = p.border, bg = p.bg_float },
    TelescopeResultsTitle = { fg = p.bg_float, bg = p.bg_float },
    TelescopePreviewNormal = { fg = p.fg, bg = p.bg_float },
    TelescopePreviewBorder = { fg = p.border, bg = p.bg_float },
    TelescopePreviewTitle = { fg = p.bg, bg = p.scrub, bold = true },
    TelescopeSelection = { fg = p.fg_bright, bg = p.bg_sel },
    TelescopeSelectionCaret = { fg = p.spice, bg = p.bg_sel },
    TelescopeMultiSelection = { fg = p.spice },
    TelescopeMatching = { fg = p.spice, bold = true },

    -- blink.cmp
    BlinkCmpMenu = { fg = p.fg_dim, bg = p.bg_float },
    BlinkCmpMenuBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpMenuSelection = { fg = p.fg_bright, bg = p.bg_sel },
    BlinkCmpScrollBarThumb = { bg = p.border },
    BlinkCmpScrollBarGutter = { bg = p.bg_float },
    BlinkCmpLabel = { fg = p.fg_dim },
    BlinkCmpLabelDeprecated = { fg = p.muted, strikethrough = true },
    BlinkCmpLabelMatch = { fg = p.spice, bold = true },
    BlinkCmpLabelDetail = { fg = p.muted },
    BlinkCmpLabelDescription = { fg = p.muted },
    BlinkCmpKind = { fg = p.ibad },
    BlinkCmpSource = { fg = p.muted },
    BlinkCmpGhostText = { fg = p.linenr, italic = true },
    BlinkCmpDoc = { fg = p.fg, bg = p.bg_float },
    BlinkCmpDocBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpDocSeparator = { fg = p.border, bg = p.bg_float },
    BlinkCmpSignatureHelp = { fg = p.fg, bg = p.bg_float },
    BlinkCmpSignatureHelpBorder = { fg = p.border, bg = p.bg_float },
    BlinkCmpSignatureHelpActiveParameter = { fg = p.spice, bold = true },

    -- trouble.nvim
    TroubleNormal = { fg = p.fg_dim, bg = p.bg_float },
    TroubleNormalNC = { fg = p.fg_dim, bg = p.bg_float },
    TroubleText = { fg = p.fg_dim },
    TroubleCount = { fg = p.spice, bg = p.bg_sel },
    TroubleIndent = { fg = p.border },
    TroublePos = { fg = p.muted },
    TroubleFileName = { fg = p.fg },
    TroubleSource = { fg = p.muted },
    TroubleCode = { fg = p.muted },

    -- toggleterm.nvim
    ToggleTerm1FloatBorder = { fg = p.border, bg = p.bg_float },
    ToggleTerm2FloatBorder = { fg = p.border, bg = p.bg_float },
    ToggleTermNormal = { fg = p.fg, bg = p.bg_float },
    ToggleTermNormalFloat = { fg = p.fg, bg = p.bg_float },

    -- mini.nvim
    MiniStatuslineModeNormal = { fg = p.bg, bg = p.spice, bold = true },
    MiniStatuslineModeInsert = { fg = p.bg, bg = p.scrub, bold = true },
    MiniStatuslineModeVisual = { fg = p.bg, bg = p.ibad, bold = true },
    MiniStatuslineModeReplace = { fg = p.bg, bg = p.blood, bold = true },
    MiniStatuslineModeCommand = { fg = p.bg, bg = p.ember, bold = true },
    MiniStatuslineModeOther = { fg = p.bg, bg = p.water, bold = true },
    MiniStatuslineDevinfo = { fg = p.fg_dim, bg = p.bg_alt },
    MiniStatuslineFilename = { fg = p.fg_dim, bg = p.bg_alt },
    MiniStatuslineFileinfo = { fg = p.fg_dim, bg = p.bg_alt },
    MiniStatuslineInactive = { fg = p.muted, bg = p.bg_alt },
    MiniSurround = { fg = p.bg, bg = p.spice },
    MiniCursorword = { bg = p.bg_sel },
    MiniCursorwordCurrent = { bg = p.bg_sel },
    MiniIndentscopeSymbol = { fg = p.border },
    MiniTrailspace = { bg = p.blood },
    MiniIconsAzure = { fg = p.ibad },
    MiniIconsBlue = { fg = p.ibad },
    MiniIconsCyan = { fg = p.water },
    MiniIconsGreen = { fg = p.scrub },
    MiniIconsGrey = { fg = p.fg_dim },
    MiniIconsOrange = { fg = p.ember },
    MiniIconsPurple = { fg = p.melange },
    MiniIconsRed = { fg = p.blood },
    MiniIconsYellow = { fg = p.spice },
  }
end
```

Modify `lua/arrakis/highlights.lua` — change the `modules` line to:

```lua
local modules = { "editor", "syntax", "diagnostics", "plugins" }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nvim --headless -l tests/run.lua`
Expected: PASS, zero failures.

- [ ] **Step 5: Commit**

```bash
git add lua/arrakis/groups/plugins.lua lua/arrakis/highlights.lua tests/plugins.lua tests/run.lua
git commit -m "Add plugin groups"
```

---

### Task 6: Terminal colours, the Ghostty twin, and the parity test

**Files:**
- Create: `lua/arrakis/groups/terminal.lua`
- Create: `extras/ghostty/arrakis`
- Create: `tests/parity.lua`
- Modify: `lua/arrakis/init.lua` (apply terminal colours inside `load()`)
- Modify: `tests/run.lua` (add `"parity"` to `specs`)

**Interfaces:**
- Consumes: `require("arrakis.palette")`.
- Produces: `require("arrakis.groups.terminal")(palette)` — sets `vim.g.terminal_color_0` through `vim.g.terminal_color_15`. This module is the one exception to the purity constraint: it writes globals and returns nothing, so `highlights.lua` does not merge it. `load()` calls it directly.

**Note:** `extras/ghostty/arrakis` has no file extension. Ghostty resolves `theme = arrakis` against `~/.config/ghostty/themes/<name>`.

- [ ] **Step 1: Write the failing test**

Create `tests/parity.lua`:

```lua
local GHOSTTY = "extras/ghostty/arrakis"

-- Ghostty accepts surrounding whitespace and either hex case. The parity
-- test must survive a reformat without reporting drift, and must still
-- catch a real value change.
local function parse(path)
  local fh = assert(io.open(path, "r"), "cannot open " .. path)
  local conf = { palette = {} }

  for line in fh:lines() do
    local stripped = line:gsub("^%s+", ""):gsub("%s+$", "")
    if stripped ~= "" and stripped:sub(1, 1) ~= "#" then
      local index, colour = stripped:match("^palette%s*=%s*(%d+)%s*=%s*(#?%x%x%x%x%x%x)$")
      if index then
        conf.palette[tonumber(index)] = "#" .. colour:gsub("^#", ""):lower()
      else
        local key, value = stripped:match("^([%w%-]+)%s*=%s*(.+)$")
        if key then
          conf[key] = value:gsub("^#", ""):lower()
        end
      end
    end
  end

  fh:close()
  return conf
end

return function(t)
  local p = require("arrakis.palette")
  local conf = parse(GHOSTTY)

  for i = 0, 15 do
    local want = p.ansi[i]:gsub("^#", "")
    local got = conf.palette[i] and conf.palette[i]:gsub("^#", "") or nil
    t.check(
      string.format("ghostty palette %d", i),
      got == want,
      string.format("got %s, want %s", tostring(got), want)
    )
  end

  local scalars = {
    background = p.bg,
    foreground = p.fg,
    ["cursor-color"] = p.spice,
    ["cursor-text"] = p.bg,
    ["selection-background"] = p.bg_sel,
    ["selection-foreground"] = p.fg,
  }

  for key, want_hex in pairs(scalars) do
    local want = want_hex:gsub("^#", "")
    t.check(
      "ghostty " .. key,
      conf[key] == want,
      string.format("got %s, want %s", tostring(conf[key]), want)
    )
  end

  -- Bright-on-bold would promote a colour every time a program bolds text,
  -- undoing the restraint rule outside the editor.
  t.check("ghostty bold-is-bright false", conf["bold-is-bright"] == "false", tostring(conf["bold-is-bright"]))

  -- vim.g.terminal_color_* must match the same 16, so :terminal and a bare
  -- Ghostty shell are indistinguishable.
  require("arrakis").setup({})
  vim.cmd.colorscheme("arrakis")

  for i = 0, 15 do
    local got = vim.g["terminal_color_" .. i]
    t.check(
      string.format("terminal_color_%d", i),
      got == p.ansi[i],
      string.format("got %s, want %s", tostring(got), p.ansi[i])
    )
  end
end
```

Modify `tests/run.lua` — change the `specs` line to:

```lua
local specs = { "contrast", "load", "syntax", "diagnostics", "plugins", "parity" }
```

- [ ] **Step 2: Run test to verify it fails**

Run: `nvim --headless -l tests/run.lua`
Expected: FAIL — the runner aborts with `cannot open extras/ghostty/arrakis`.

- [ ] **Step 3: Write minimal implementation**

Create `lua/arrakis/groups/terminal.lua`:

```lua
-- The one impure group module: it writes globals rather than returning a
-- highlight table, so highlights.lua does not merge it. load() calls it.
return function(p)
  for i = 0, 15 do
    vim.g["terminal_color_" .. i] = p.ansi[i]
  end
end
```

Modify `lua/arrakis/init.lua` — add the terminal call as the last statement of `load()`, after the `nvim_set_hl` loop:

```lua
  for group, spec in pairs(require("arrakis.highlights").build(M.options)) do
    vim.api.nvim_set_hl(0, group, spec)
  end

  require("arrakis.groups.terminal")(require("arrakis.palette"))
end
```

Create `extras/ghostty/arrakis`:

```
# Arrakis — desert night
#
# Install:
#   cp extras/ghostty/arrakis ~/.config/ghostty/themes/arrakis
# then in ~/.config/ghostty/config:
#   theme = arrakis
#
# Hand-maintained twin of lua/arrakis/palette.lua. tests/parity.lua fails
# if the two drift.

background = 1a150f
foreground = e3d2b4

cursor-color = d8a657
cursor-text = 1a150f

selection-background = 2e261b
selection-foreground = e3d2b4

# Bright-on-bold would promote a colour every time a program bolds text.
bold-is-bright = false

palette = 0=#1a150f
palette = 1=#d1554a
palette = 2=#8aa66b
palette = 3=#d8a657
palette = 4=#4fa8c5
palette = 5=#b07ea8
palette = 6=#5fa89b
palette = 7=#bcab92
palette = 8=#564a3c
palette = 9=#e0705c
palette = 10=#9dbb7c
palette = 11=#e8bd6e
palette = 12=#6fc0d8
palette = 13=#c795bd
palette = 14=#7cc4b6
palette = 15=#f7ecd6
```

- [ ] **Step 4: Run test to verify it passes**

Run: `nvim --headless -l tests/run.lua`
Expected: PASS, zero failures.

- [ ] **Step 5: Verify the parity test actually catches drift**

A parity test that cannot fail is worse than no parity test. Prove it fails, then restore.

```bash
sed -i '' 's/^palette = 3=#d8a657$/palette = 3=#ffffff/' extras/ghostty/arrakis
nvim --headless -l tests/run.lua; echo "exit: $?"
```

Expected: FAIL with `ghostty palette 3 — got ffffff, want d8a657` and `exit: 1`.

Then restore and confirm green again:

```bash
sed -i '' 's/^palette = 3=#ffffff$/palette = 3=#d8a657/' extras/ghostty/arrakis
nvim --headless -l tests/run.lua; echo "exit: $?"
```

Expected: PASS with `exit: 0`.

- [ ] **Step 6: Commit**

```bash
git add lua/arrakis/groups/terminal.lua lua/arrakis/init.lua extras/ghostty/arrakis tests/parity.lua tests/run.lua
git commit -m "Add terminal colours and Ghostty theme with parity test"
```

---

### Task 7: README

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: the public API from Tasks 2 and 6.
- Produces: nothing consumed by code.

- [ ] **Step 1: Write the README**

`<you>` appears twice in the install snippets below and once in Task 8. It is the GitHub owner the repository will be pushed under, which is not decided yet. Leave it literal — do not invent a username — and flag it to the user at the end of this task so it gets filled in before the repo is published.

Create `README.md`:

````markdown
# arrakis.nvim

A desert-night colourscheme for Neovim, with a matching Ghostty theme.

Dark only. One rule governs every colour in it:

> A token gets a hue only if the hue tells you something its name cannot.

Keywords, strings and types carry hue. Names, fields, parameters and
punctuation stay on the sand ramp. Functions are lifted in brightness, not
in hue. Mostly beige, with the occasional flash of spice.

## Requirements

Neovim 0.10 or newer, and a terminal with truecolour support.

## Install

With `vim.pack` (Neovim 0.12+):

```lua
vim.pack.add({ { src = "https://github.com/<you>/arrakis.nvim" } })
vim.cmd.colorscheme("arrakis")
```

With lazy.nvim:

```lua
{
  "<you>/arrakis.nvim",
  priority = 1000,
  config = function()
    vim.cmd.colorscheme("arrakis")
  end,
}
```

## Configuration

Calling `setup()` is optional. Call it before `:colorscheme arrakis`.

```lua
require("arrakis").setup({
  transparent = false,     -- drop backgrounds so the terminal shows through
  italic_comments = true,  -- italics on comments
  overrides = {},          -- highlight groups, applied last and always winning
})
vim.cmd.colorscheme("arrakis")
```

`overrides` takes anything `vim.api.nvim_set_hl` accepts, including groups
the theme does not otherwise set:

```lua
require("arrakis").setup({
  overrides = {
    Comment = { fg = "#8f8170", italic = false },
    ["@keyword"] = { bold = true },
  },
})
```

## Ghostty

```sh
cp extras/ghostty/arrakis ~/.config/ghostty/themes/arrakis
```

Then in `~/.config/ghostty/config`:

```
theme = arrakis
```

The terminal's ANSI 16 and Neovim's `terminal_color_*` come from the same
values, so `:terminal` and a bare shell look identical.

## Palette

Both sides are maintained by hand. This table is the reference for
reconciling them; `tests/parity.lua` fails if they drift.

| role | hex | | role | hex |
| --- | --- | --- | --- | --- |
| `bg` | `#1a150f` | | `ember` keywords | `#c4643a` |
| `bg_float` | `#1e1812` | | `spice` strings | `#d8a657` |
| `bg_alt` | `#231c15` | | `ibad` types | `#4fa8c5` |
| `bg_sel` | `#2e261b` | | `num` constants | `#bf9a5e` |
| `border` | `#403629` | | `scrub` | `#8aa66b` |
| `linenr` | `#564a3c` | | `water` | `#5fa89b` |
| `muted` comments | `#746455` | | `melange` | `#b07ea8` |
| `subtle` punctuation | `#8f8170` | | `blood` errors | `#d1554a` |
| `fg_dim` vars | `#bcab92` | | | |
| `fg` | `#e3d2b4` | | | |
| `fg_bright` functions | `#f7ecd6` | | | |

Every foreground clears WCAG AA against the background; comments and
chrome sit deliberately below it. The thresholds are asserted by
`tests/contrast.lua`.

## Plugins

Themed: [oil.nvim], [telescope.nvim], [blink.cmp], [trouble.nvim],
[toggleterm.nvim], [mini.nvim], [gitsigns.nvim].

[oil.nvim]: https://github.com/stevearc/oil.nvim
[telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[blink.cmp]: https://github.com/saghen/blink.cmp
[trouble.nvim]: https://github.com/folke/trouble.nvim
[toggleterm.nvim]: https://github.com/akinsho/toggleterm.nvim
[mini.nvim]: https://github.com/nvim-mini/mini.nvim
[gitsigns.nvim]: https://github.com/lewis6991/gitsigns.nvim

## Tests

From the repository root:

```sh
nvim --headless -l tests/run.lua
```

No framework and no dependencies. Three things are checked: that the
scheme loads and every group resolves, that every colour clears its
contrast threshold, and that the Ghostty theme has not drifted from the
Lua palette.

## Licence

MIT
````

- [ ] **Step 2: Verify the documented commands actually work**

The README is the install path a stranger follows; a wrong command there is a real defect. Verify each claim:

```bash
nvim --headless -l tests/run.lua; echo "exit: $?"
nvim --headless -u NONE --cmd "set rtp+=$(pwd)" -c "lua require('arrakis').setup({ transparent = true, overrides = { Comment = { fg = '#8f8170', italic = false } } })" -c "colorscheme arrakis" -c "lua io.stdout:write(vim.inspect(vim.api.nvim_get_hl(0, { name = 'Comment' })) .. '\n')" -c "qa"
```

Expected: the first prints `exit: 0`. The second prints a `Comment` definition with `italic` absent or false and no error — confirming the README's `setup()` snippet is valid as written.

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Add README"
```

---

### Task 8: Adopt the theme locally

**Files:**
- Modify: `~/.config/nvim/init.lua`
- Modify: `~/.config/nvim/ghostty.conf`
- Create: `~/.config/ghostty/themes/arrakis`

This task edits files outside the repository. Confirm with the user before running it; it changes their daily editor and terminal.

- [ ] **Step 1: Install the Ghostty theme**

```bash
cp extras/ghostty/arrakis ~/.config/ghostty/themes/arrakis
```

- [ ] **Step 2: Point Ghostty at it**

In `~/.config/nvim/ghostty.conf`, replace:

```
theme="Rose Pine Moon"
```

with:

```
theme = arrakis
```

- [ ] **Step 3: Point Neovim at it**

In `~/.config/nvim/init.lua`, add the repository to `vim.pack.add`'s list alongside the existing entries:

```lua
    { src = "https://github.com/<you>/arrakis.nvim" },
```

and replace:

```lua
vim.cmd.colorscheme("moonfly")
```

with:

```lua
vim.cmd.colorscheme("arrakis")
```

Until the repository is pushed, use a local path instead of the `vim.pack` entry:

```lua
vim.opt.runtimepath:prepend("~/Developer/stuff/nvim.arrakis")
vim.cmd.colorscheme("arrakis")
```

- [ ] **Step 4: Verify it loads in the real config**

```bash
nvim --headless -c "lua io.stdout:write(vim.g.colors_name .. '\n')" -c "qa"
```

Expected: prints `arrakis`.

- [ ] **Step 5: Open a real file and look at it**

Open a source file in each of a few languages and check the restraint rule holds in practice — that comments recede, strings and keywords separate cleanly, and the `colorcolumn=80` rule sits below the cursorline in weight.

```bash
nvim lua/arrakis/groups/syntax.lua
```

This step is a human judgement, not an assertion. If something reads wrong, the fix is a palette change in `lua/arrakis/palette.lua` plus the matching edit to `extras/ghostty/arrakis` — and the contrast and parity tests will tell you if the change broke either invariant.
