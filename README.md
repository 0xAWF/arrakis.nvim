<p align="center">
  <h2 align="center">ARRAKIS.nvim</h2>
</p>

<p align="center">A Neovim dark colourscheme inspired by the deserts of Arrakis, with a matching Ghostty theme.</p>

<p align="center">
  <img alt="Preview" src="assets/nvim.png" width=1000>
</p>

## Features

- One rule governs every colour: **a token gets a hue only if the hue tells you something its name cannot.** Keywords, strings and types carry hue; names, fields, parameters and punctuation stay on the sand ramp, and functions are lifted in brightness rather than hue
- Extensive `TreeSitter` support, with every `@lsp.type.*` semantic token pinned to its treesitter twin so the theme looks the same in every language
- Popular plugins styled explicitly rather than left to inherit
- A matching Ghostty theme sharing the same ANSI 16, so `:terminal` and a bare shell are indistinguishable
- Every syntax foreground clears WCAG AA against the background; comments and chrome sit deliberately below it

## Installation

Download with your favourite package manager.

```lua
vim.pack.add({ { src = "https://github.com/0xAWF/arrakis.nvim" } })
```

```lua
{ "0xAWF/arrakis.nvim", priority = 1000 }
```

## Requirements

- Neovim 0.10 or later
- truecolor terminal support
- undercurl terminal support (optional)

## Usage

As simple as writing (pasting)

```vim
colorscheme arrakis
```

```lua
vim.cmd("colorscheme arrakis")
```

## Configuration

There is no need to call setup if you are ok with the defaults.

```lua
require("arrakis").setup({
    transparent = false,     -- drop backgrounds so the terminal shows through
    italic_comments = true,  -- italics on comments
    overrides = {},          -- highlight groups, applied last and always winning
})

vim.cmd("colorscheme arrakis")
```

`setup()` must be called before `colorscheme`.

## Customization

`overrides` takes anything `vim.api.nvim_set_hl` accepts, including groups the
theme does not otherwise set. It is merged last, so it always wins.

```lua
require("arrakis").setup({
    overrides = {
        Comment = { fg = "#8f8170", italic = false },
        ["@keyword"] = { bold = true },
    },
})
```

### Common customizations

#### Transparent background

```lua
require("arrakis").setup({ transparent = true })
```

Backgrounds are dropped from `Normal`, `SignColumn`, `WinBar`, the tabline and
every plugin float. Selection rows — `Visual`, `PmenuSel`, `TelescopeSelection`
— keep theirs, or there would be nothing left to show the selection.

#### Borderless floats

```lua
local p = require("arrakis.palette")

require("arrakis").setup({
    overrides = {
        FloatBorder = { fg = p.bg_float, bg = p.bg_float },
        TelescopeBorder = { fg = p.bg_float, bg = p.bg_float },
    },
})
```

#### Brighter comments

`muted` sits at 3.19:1 against the background, which is deliberate — comments
are meant to recede. If you want them louder, `subtle` is the next step up at
4.79:1.

```lua
local p = require("arrakis.palette")

require("arrakis").setup({ overrides = { Comment = { fg = p.subtle, italic = true } } })
```

## Integration

### Get palette colours

```lua
local p = require("arrakis.palette")

p.spice      --> "#d8a657"
p.ansi[3]    --> "#d8a657", the same value the Ghostty theme uses
```

### Ghostty

Copy [`extras/ghostty/arrakis`](extras/ghostty/arrakis) into your themes
directory and select it:

```sh
cp extras/ghostty/arrakis ~/.config/ghostty/themes/arrakis
```

```
theme = arrakis
```

The themes directory is `~/.config/ghostty/themes/` on every platform, but the
config file itself is `~/.config/ghostty/config` only on Linux and BSD — on
macOS it is `~/Library/Application Support/com.mitchellh.ghostty/config`, and a
`~/.config/ghostty/config` you create there is silently ignored.

### Terminal integration

`vim.g.terminal_color_0` through `15` are set from the same ANSI table the
Ghostty theme uses, so `:terminal` matches the shell around it with no extra
configuration.

<details>
<summary><h2>Colour palette</h2></summary>

|                                                      | Name      |    Hex    | Usage                                                     |
| :--------------------------------------------------: | :-------- | :-------: | :-------------------------------------------------------- |
| <img src="assets/circles/fg_bright.svg" width="40">  | fg_bright | `#f7ecd6` | Functions, headings, bold text                            |
| <img src="assets/circles/fg.svg" width="40">         | fg        | `#e3d2b4` | Default foreground                                        |
| <img src="assets/circles/fg_dim.svg" width="40">     | fg_dim    | `#bcab92` | Variables, fields, parameters                             |
| <img src="assets/circles/subtle.svg" width="40">     | subtle    | `#8f8170` | Punctuation, operators, delimiters                        |
| <img src="assets/circles/muted.svg" width="40">      | muted     | `#746455` | Comments, folds                                           |
| <img src="assets/circles/linenr.svg" width="40">     | linenr    | `#564a3c` | Line numbers, non-text characters, inlay hints            |
| <img src="assets/circles/border.svg" width="40">     | border    | `#403629` | Float borders, window separators                          |
| <img src="assets/circles/bg_sel.svg" width="40">     | bg_sel    | `#2e261b` | Visual selection, popup selection, search background      |
| <img src="assets/circles/bg_alt.svg" width="40">     | bg_alt    | `#231c15` | Cursorline, colorcolumn, statusline, folds                |
| <img src="assets/circles/bg_float.svg" width="40">   | bg_float  | `#1e1812` | Floating windows and popup menus                          |
| <img src="assets/circles/bg.svg" width="40">         | bg        | `#1a150f` | Default background                                        |
| <img src="assets/circles/ember.svg" width="40">      | ember     | `#c4643a` | Keywords, conditionals, `self` and `this`, string escapes |
| <img src="assets/circles/spice.svg" width="40">      | spice     | `#d8a657` | Strings, cursor, headings, warnings                       |
| <img src="assets/circles/ibad.svg" width="40">       | ibad      | `#4fa8c5` | Types, directories, links, diagnostic info                |
| <img src="assets/circles/num.svg" width="40">        | num       | `#bf9a5e` | Numbers, booleans, constants                              |
| <img src="assets/circles/scrub.svg" width="40">      | scrub     | `#8aa66b` | Diagnostic hints, git add, raw markup                     |
| <img src="assets/circles/water.svg" width="40">      | water     | `#5fa89b` | ANSI cyan, symlinks                                       |
| <img src="assets/circles/melange.svg" width="40">    | melange   | `#b07ea8` | ANSI magenta, rare spelling                               |
| <img src="assets/circles/blood.svg" width="40">      | blood     | `#d55d4f` | Errors, git delete                                        |
| <img src="assets/circles/err_dim.svg" width="40">    | err_dim   | `#6e352c` | Error virtual text                                        |
| <img src="assets/circles/warn_dim.svg" width="40">   | warn_dim  | `#6f572f` | Warning virtual text                                      |
| <img src="assets/circles/info_dim.svg" width="40">   | info_dim  | `#325861` | Info virtual text                                         |
| <img src="assets/circles/hint_dim.svg" width="40">   | hint_dim  | `#4c5738` | Hint virtual text                                         |

`ember` has the least headroom of any accent, at 4.52:1 against a 4.5 floor —
it cannot be darkened. The Lua palette and the Ghostty theme are maintained by
hand, so a change to one has to be made in the other.

</details>

## Licence

MIT
