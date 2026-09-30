# Arrakis — a Dune-inspired theme for Neovim and Ghostty

Date: 2026-09-30
Status: approved

## Intent

A single desert-night theme, shipped as a publishable Neovim plugin with a
matching Ghostty terminal theme. The author uses it daily; publishing is a
real goal, not an afterthought, so the repo carries a plugin layout, a
README and tests.

The theme is **dark only**. There is no light variant, now or planned.

Success means: the author replaces `moonfly` with it in
`~/.config/nvim/init.lua`, replaces `Rose Pine Moon` in
`~/.config/ghostty/ghostty.conf`, and a stranger can install both from the
README without asking a question.

### The restraint rule

One rule governs every colour decision:

> A token gets a hue only if the hue tells you something its name cannot.

Keywords, strings and types carry hue. Names, fields, parameters and
punctuation sit on the sand ramp. Functions are lifted in brightness, not
in hue. The screen should read as a desert — mostly beige, with the
occasional flash of spice.

When a future change is ambiguous, this rule decides it.

## Palette

Source of truth: `lua/arrakis/palette.lua`. Every hex in the project
appears there exactly once.

### Base ramp

| name | hex | use |
| --- | --- | --- |
| `bg` | `#1a150f` | `Normal` background |
| `bg_float` | `#1e1812` | `NormalFloat`, `Pmenu` |
| `bg_alt` | `#231c15` | `CursorLine`, `ColorColumn` |
| `bg_sel` | `#2e261b` | `Visual`, `PmenuSel` |
| `border` | `#403629` | `FloatBorder`, `WinSeparator` |
| `linenr` | `#564a3c` | `LineNr`, `NonText` |
| `muted` | `#746455` | `Comment` |
| `subtle` | `#8f8170` | punctuation, delimiters, operators |
| `fg_dim` | `#bcab92` | variables, fields, parameters |
| `fg` | `#e3d2b4` | `Normal` foreground |
| `fg_bright` | `#f7ecd6` | functions, headings, bold |

### Accents

| name | hex | use |
| --- | --- | --- |
| `ember` | `#c4643a` | keywords, conditionals, `@variable.builtin` |
| `spice` | `#d8a657` | strings, cursor, warnings |
| `ibad` | `#4fa8c5` | types, info |
| `num` | `#bf9a5e` | numbers, booleans, constants |
| `scrub` | `#8aa66b` | hints, git add |
| `water` | `#5fa89b` | ANSI cyan |
| `melange` | `#b07ea8` | ANSI magenta |
| `blood` | `#d55d4f` | errors |

`ember` is editor-only; it has no ANSI slot, since ANSI has no orange.

### Dimmed diagnostic variants

Hardcoded, not blended at runtime. Each is 45% accent over `bg`.

| name | hex |
| --- | --- |
| `err_dim` | `#6e352c` |
| `warn_dim` | `#6f572f` |
| `info_dim` | `#325861` |
| `hint_dim` | `#4c5738` |

### ANSI 16

Shared verbatim by `vim.g.terminal_color_0..15` and Ghostty's `palette =`
lines, so `:terminal`, toggleterm and a bare Ghostty shell are
indistinguishable.

| # | hex | | # | hex |
| --- | --- | --- | --- | --- |
| 0 | `#1a150f` | | 8 | `#564a3c` |
| 1 | `#d55d4f` | | 9 | `#e0705c` |
| 2 | `#8aa66b` | | 10 | `#9dbb7c` |
| 3 | `#d8a657` | | 11 | `#e8bd6e` |
| 4 | `#4fa8c5` | | 12 | `#6fc0d8` |
| 5 | `#b07ea8` | | 13 | `#c795bd` |
| 6 | `#5fa89b` | | 14 | `#7cc4b6` |
| 7 | `#bcab92` | | 15 | `#f7ecd6` |

### Measured contrast

Computed against `bg` `#1a150f` during design, not asserted by eye:

| colour | ratio |
| --- | --- |
| `fg_bright` | 15.67:1 |
| `fg` | 12.50:1 |
| `spice` | 8.41:1 |
| `fg_dim` | 8.28:1 |
| `num` | 7.07:1 |
| `scrub` | 6.85:1 |
| `ibad` | 6.84:1 |
| `water` | 6.67:1 |
| `melange` | 5.62:1 |
| `subtle` | 4.87:1 |
| `ember` | 4.62:1 |
| `blood` | 4.76:1 |
| `muted` | 3.27:1 |
| `linenr` | 2.16:1 |
| `border` | 1.56:1 |

`blood` began as `#c9453d`, which measured 3.89:1 and failed the accent
threshold below. It was lightened at the same hue, first to `#d1554a` —
which hand-arithmetic put at 4.52:1 but `tests/contrast.lua` measured at
4.41:1, still failing — and then to `#d55d4f`, measured at 4.76:1.

## Architecture

Two hand-maintained sides. Nothing is generated; the Ghostty file is
written and edited by hand exactly like the Lua. A test — read-only —
fails if the two drift.

```
colors/arrakis.lua                     entry point; requires and loads
lua/arrakis/
  init.lua                             setup(opts), load()
  palette.lua                          every hex, once
  highlights.lua                       assembles the group table
  groups/
    editor.lua                         chrome
    syntax.lua                         treesitter + LSP semantic tokens
    diagnostics.lua                    diagnostics, git, diff
    plugins.lua                        oil, telescope, blink, trouble,
                                       toggleterm, mini, gitsigns
    terminal.lua                       g:terminal_color_0..15
extras/ghostty/arrakis                 the Ghostty twin (no extension)
tests/run.lua                          headless runner
README.md                              install + the palette table
```

Each `groups/*.lua` module exports a single function taking the palette
and returning a flat `{ [group] = spec }` table. `highlights.lua` merges
them in a fixed order and applies `opts.overrides` last. A module can be
read and changed without reading any other.

### `setup(opts)`

Three options, deliberately:

| option | default | effect |
| --- | --- | --- |
| `transparent` | `false` | `Normal`/`NormalFloat`/`SignColumn` backgrounds become `NONE` |
| `italic_comments` | `true` | italics on `Comment` |
| `overrides` | `{}` | merged over the final group table |

`colors/arrakis.lua` calls `load()` with whatever `setup()` last stored,
so `:colorscheme arrakis` works with or without a prior `setup()` call.

## Highlight map

### Syntax

| group | colour |
| --- | --- |
| `Comment`, `@comment` | `muted`, italic |
| `Keyword`, `Conditional`, `Repeat`, `@keyword.*` | `ember` |
| `@variable.builtin` (`self`, `this`) | `ember` |
| `@string.escape` | `ember` |
| `String`, `Character`, `@string` | `spice` |
| `Type`, `@type`, `@type.builtin` | `ibad` |
| `Number`, `Boolean`, `Constant`, `@constant` | `num` |
| `Function`, `@function`, `@function.call`, `@method` | `fg_bright` |
| `@variable`, `@property`, `@field`, `@parameter` | `fg_dim` |
| `@punctuation.*`, `@operator`, `Delimiter` | `subtle` |
| `@constructor`, `@module`, `@namespace` | `fg` |
| `@tag` | `ember` |
| `@tag.attribute` | `fg_dim` |
| `@tag.delimiter` | `subtle` |
| `@markup.heading` | `spice`, bold |
| `@markup.link` | `ibad`, underline |
| `@markup.raw` | `scrub` |
| `@comment.todo` | `ibad`, bold |
| `@comment.warning` | `spice`, bold |
| `@comment.error` | `blood`, bold |

### LSP semantic tokens

Every `@lsp.type.*` and `@lsp.mod.*` group used in practice is pinned
explicitly to its treesitter twin. This is not optional polish: semantic
tokens are applied *over* treesitter, so leaving them unmapped lets a
language server's defaults punch colour through the restraint rule, and
the theme would look different in Rust than in Lua.

Minimum set to pin: `class`, `struct`, `enum`, `interface`, `typeParameter`
→ `ibad`; `function`, `method` → `fg_bright`; `variable`, `property`,
`parameter` → `fg_dim`; `keyword` → `ember`; `string` → `spice`;
`number`, `enumMember` → `num`; `namespace` → `fg`; `comment` → `muted`.

### Editor chrome

`Normal` `fg`/`bg` · `NormalFloat` `bg_float` · `FloatBorder`/`WinSeparator`
`border` · `CursorLine` `bg_alt` · `CursorLineNr` `spice` · `LineNr`
`linenr` · `SignColumn` `bg` · `ColorColumn` `bg_alt` · `Visual` `bg_sel` ·
`Search` `bg_sel` on `fg` · `IncSearch` `bg` on `spice` · `MatchParen`
`spice` + underline · `Pmenu` `bg_float` · `PmenuSel` `bg_sel` ·
`StatusLine` `fg_dim` on `bg_alt` · `Folded` `muted` on `bg_alt` ·
`NonText`/`Whitespace` `linenr` · `WinBar` `fg_dim`.

`ColorColumn` matters here: the author runs `colorcolumn=80`, so it is on
screen constantly and must sit below `CursorLine` in visual weight.

### Diagnostics

| group | colour |
| --- | --- |
| `DiagnosticError` | `blood` |
| `DiagnosticWarn` | `spice` |
| `DiagnosticInfo` | `ibad` |
| `DiagnosticHint`, `DiagnosticOk` | `scrub` |

`DiagnosticUnderline*` use undercurl in the matching accent.
`DiagnosticVirtualText*` use the corresponding `*_dim`.

### Git and diff

`DiffAdd`/`GitSignsAdd` `scrub` · `DiffChange`/`GitSignsChange` `spice` ·
`DiffDelete`/`GitSignsDelete` `blood` · `DiffText` `spice` on `bg_sel`.

### Plugins

Themed: **oil.nvim**, **telescope.nvim**, **blink.cmp**, **trouble.nvim**,
**toggleterm.nvim**, **mini.nvim**, **gitsigns**.

The first six are what the author runs. Gitsigns is included because the
`Diff*` groups are needed for `:diffthis` regardless, and a published
theme that omits gitsigns will draw an issue in its first week.

No other plugin is themed. Requests get evaluated against the restraint
rule when they arrive.

## Ghostty

`extras/ghostty/arrakis`, no file extension — Ghostty resolves
`theme = arrakis` against `~/.config/ghostty/themes/<name>`.

```
background = 1a150f
foreground = e3d2b4
cursor-color = d8a657
cursor-text = 1a150f
selection-background = 2e261b
selection-foreground = e3d2b4
bold-is-bright = false
palette = 0=#1a150f
...through 15
```

`bold-is-bright = false` is deliberate and differs from the author's
existing `koda-dark.conf`. Bright-on-bold would promote a colour every
time a program bolds text, undoing the restraint rule outside the editor.

## Verification

`nvim --headless -l tests/run.lua`. No test framework, no new
dependencies; it runs against the Neovim already installed.

**1. Load test.** Apply the colorscheme headless, assert it does not
error, and assert a representative sample of groups resolves to a
non-empty definition via `nvim_get_hl`. Catches typos and nil palette
references, which is the large majority of what actually breaks a theme.

**2. Contrast test.** Compute WCAG relative luminance in Lua and assert,
against `bg`:

| class | threshold |
| --- | --- |
| `fg`, `fg_bright`, `fg_dim` | ≥ 7:1 |
| accents (`ember`, `spice`, `ibad`, `num`, `scrub`, `water`, `melange`, `blood`) | ≥ 4.5:1 |
| `subtle` | ≥ 4.5:1 |
| `muted` | ≥ 3:1 |
| `linenr` | ≥ 2:1 |
| `border` | ≥ 1.5:1 |

Comments and chrome sit below the text bar by design — they are meant to
recede — so they get their own lower thresholds rather than being
exempted. `border` is decoration rather than information and gets the
loosest bar of all; it measures 1.56:1.

**3. Ghostty parity test.** Parse `extras/ghostty/arrakis`, extract its 16
`palette =` entries plus `background` and `foreground`, and assert they
equal `palette.ansi`, `palette.bg` and `palette.fg`. Read-only: it
generates nothing and never writes the conf. It exists so that the one
real cost of hand-maintaining both sides — silent drift — fails loudly
instead.

## Out of scope

- A light variant.
- Any build or generation step.
- Lualine/airline/heirline themes, until asked for.
- Terminal themes beyond Ghostty (tmux, bat, kitty, wezterm).
- A `blend()` helper. Dimmed colours are hardcoded; there are four.

## Open questions

None.
