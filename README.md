# 🪓 substitute.nvim

![Lua](https://img.shields.io/badge/Made%20with%20Lua-blueviolet.svg?style=for-the-badge&logo=lua)
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/gbprod/substitute.nvim/integration.yml?branch=main&style=for-the-badge)](https://github.com/gbprod/substitute.nvim/actions/workflows/integration.yml)

`substitute.nvim` aim is to provide new operator motions to make it very easy to perform quick substitutions and exchange.

If you are familiar with [svermeulen/vim-subversive](https://github.com/svermeulen/vim-subversive) and
[tommcdo/vim-exchange](https://github.com/tommcdo/vim-exchange), this plugin does almost the same but
rewritten in `lua` (and I hope this will be more maintainable, readable and efficient).

## ✨ Features

- [Substitute operator](#-substitute-operator)
- [Substitute over range motion](#-substitute-over-range-motion)
- [Exchange operator](#-exchange-operator)

[See this plugin in action](DEMO.md)

## ⚡️ Requirements

- Neovim >= 0.8.0

([Neovim 0.6.0 compat](https://github.com/gbprod/substitute.nvim/tree/0.6-compat))

## 📦 Installation

Install the plugin with your preferred package manager:

### [packer](https://github.com/wbthomason/packer.nvim)

```lua
-- Lua
use({
  "gbprod/substitute.nvim",
  config = function()
    require("substitute").setup({
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    })
  end
})
```

### [vim-plug](https://github.com/junegunn/vim-plug)

```viml
" Vim Script
Plug 'gbprod/substitute.nvim'
lua << EOF
  require("substitute").setup({
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  })
EOF
```

## ⚙️ Configuration

Substitute comes with the following defaults:

```lua
{
  on_substitute = nil,
  yank_substituted_text = false,
  preserve_cursor_position = false,
  modifiers = nil,
  highlight_substituted_text = {
    enabled = true,
    timer = 500,
  },
  range = {
    prefix = "s",
    prompt_current_text = false,
    confirm = false,
    complete_word = false,
    motion1 = false,
    motion2 = false,
    suffix = "",
  },
  exchange = {
    motion = false,
    use_esc_to_cancel = true,
    preserve_cursor_position = false,
  },
}
```

More details on these options is available in the sections below corresponding to the different features.

## 🔂 Substitute operator

It contains no default mappings and will have no effect until you add your own maps to it.

```lua
-- Lua
vim.keymap.set("n", "s", require('substitute').operator, { noremap = true })
vim.keymap.set("n", "ss", require('substitute').line, { noremap = true })
vim.keymap.set("n", "S", require('substitute').eol, { noremap = true })
vim.keymap.set("x", "s", require('substitute').visual, { noremap = true })
```

Then you can then execute `s<motion>` to substitute the text object provided by the motion with the contents of
the default register (or an explicit register if provided). For example, you could execute siw to replace the
current word under the cursor with the current yank, or sip to replace the paragraph, etc.

This action is dot-repeatable.

Note: in this case you will be shadowing the change character key `s` so you will have to use the longer form `cl`.

Each functions (`operator`, `line`, `eol` and `visual`) are configurable:

```lua
lua require('substitute').operator({
  count = 1,       -- number of substitutions
  register = "a",  -- register used for substitution
  motion = "iw",   -- only available for `operator`, this will automatically use
                   -- this operator for substitution instead of asking for.
  modifiers = nil, -- this allows to modify substitued text, will override the default
                   -- configuration (see below)
})
```

### ⚙️ Configuration

#### `on_substitute`

Default : `nil`

Function that will be called each times a substitution is made. This function takes a `param` argument that contains the `register` used for substitution.

#### `yank_substituted_text`

Default : `false`

If `true`, when performing a substitution, substitued text is pushed into the default register.

#### `highlight_substituted_text.enabled`

Default : `true`

If `true` will temporary highlight substitued text.

#### `highlight_substituted_text.timer`

Default : `500`

Define the duration of highlight.

#### `preserve_cursor_position`

Default : `false`

If `true`, the cursor position will be preserved when performing a substitution.

#### `modifiers`

Default : `nil`

Could be a function or a table of transformations that will be called to modify substitued text. See modifiers section below.

### ➰ Modifiers

Modifiers are used to modify the text before substitution is performed. You can chain those modifiers or even use a function to dynamicly choose modifier depending on the context.

Available modifiers are:

- `linewise` : will create a new line for substitution ;
- `reindent` : will reindent substitued text ;
- `trim` : will trim substitued text ;
- `join` : will join lines of substitued text.

### Examples

If you want to create a new line for substitution and reindent, you can use:

```lua
require('substitute').operator({
  modifiers = { 'linewise', 'reindent' },
})
```

If you want to trim and join lines of substitued text, you can use:

```lua
require('substitute').operator({
  modifiers = { 'join', 'trim' },
})
```

If you want to trim text but only if you substitute text in a charwise motion, you can use:

```lua
require('substitute').operator({
  modifiers = function(state)
    if state.vmode == 'char' then
      return { 'trim' }
    end
  end,
})
```

If you always want to reindent text when making a linewise substitution, you can use:

```lua
require('substitute').operator({
  modifiers = function(state)
    if state.vmode == 'line' then
      return { 'reindent' }
    end
  end,
})
```

### 🤝 Integration

<details>
<summary><b>gbprod/yanky.nvim</b></summary>

To enable [gbprod/yanky.nvim](https://github.com/gbprod/yanky.nvim) swap when performing a substitution, you can add this to your setup:

```lua
require("substitute").setup({
  on_substitute = require("yanky.integration").substitute(),
})
```

</details>

<details>
<summary><b>svermeulen/vim-yoink</b></summary>

To enable [vim-yoink](https://github.com/svermeulen/vim-yoink) swap when performing a substitution, you can add this to your setup:

```lua
require("substitute").setup({
  on_substitute = function(_)
    vim.cmd("call yoink#startUndoRepeatSwap()")
  end,
})
```

[vim-yoink](https://github.com/svermeulen/vim-yoink) does not support swapping when doing paste in visual mode.
With this plugin, you can add thoss mappings to enable it :

```lua
vim.keymap.set("x", "p", require('substitute').visual, { noremap = true })
vim.keymap.set("x", "P", require('substitute').visual, { noremap = true })
```

</details>

## 🔁 Substitute over range motion

Another operator provided allows specifying both the text to replace and the line range over which to apply the
change by using multiple consecutive motions.

```lua
vim.keymap.set("n", "<leader>s", require('substitute.range').operator, { noremap = true })
vim.keymap.set("x", "<leader>s", require('substitute.range').visual, { noremap = true })
vim.keymap.set("n", "<leader>ss", require('substitute.range').word, { noremap = true })
```

After adding this map, if you execute `<leader>s<motion1><motion2>` then the command line will be filled with a
substitute command that allow to replace the text given by `motion1` by the text will enter in the command line for each
line provided by `motion2`.

Alternatively, we can also select `motion1` in visual mode and then hit `<leader>s<motion2>` for the same effect.

For convenience, `<leader>ss<motion2>` can be used to select complete word under the cursor as motion1 (complete word
means that `complete_word` options is override to `true` so is different from <leader>siwip which will not require that
there be word boundaries on each match).

You can select the default replacement value by selecting a register. Eg: `"a<leader>s<motion1><motion2>` will use the
content of `a` register as replacement value.

You can override any default configuration (described later) by passing this to the operator function. By example,
this will use `S` as prefix of the substitution command (and use [tpope/vim-abolish](https://github.com/tpope/vim-abolish)):

```lua
vim.keymap.set("n", "<leader>S", function ()
    require('substitute.range').operator({ prefix = 'S' })
end, { noremap = true })
```

### ⚙️ Configuration

#### `range.prefix`

Default : `s`

Substitution command that will be used (set it to `S` to use [tpope/vim-abolish](https://github.com/tpope/vim-abolish) substitution by default).

#### `range.suffix`

Default : `""`

Suffix added at the end of the substitute command. For example, it can be used to not save substitution history calls by adding `| call histdel(':', -1)`.

#### `range.prompt_current_text`

Default : `false`

Substitution command replace part will be set to the current text. Eg. instead of `s/pattern//g` you will have `s/pattern/pattern/g`.

#### `range.confirm`

Default : `false`

Will ask for confirmation for each substitutions.

#### `range.complete_word`

Default : `false`

Will require that there be word boundaries on each match (eg: `\<word\>` instead of `word`).

#### `range.group_substituted_text`

Default : `false`

This will capture substituted text as you can use `\1` to quickly reuse it.

#### `range.subject`

Default : `nil`

This allows you to control how the subject (to be replaced) is resolved. It
accepts either a function, string, or a table with some special keys.

If it is a string that will be used directly. If it is a function it will be
called when the operator is used, and should return the subject to be replaced.
If it is a table you may provide one of the following keys with appropriate values:

- `register = "a"` Use the contents of this register as the subject.
- `expand = "<cword>"` Use the string given as the argument to `vim.fn.expand()` to get the subject.
- `last_search = true` Shortcut for `register = "/"` to use the last `/` search.
- `motion = "iw"` Use this motion at the current cursor to get the subject

eg. `lua require('substitute.range').operator({ subject = {motion = 'iW'} })`
will select inner WORD as subject of substitution.

#### `range.range`

Default : `nil`

This allows you to control the range of the substitution. This takes either a
function, string, or a table with some special keys. If it is a string that
will be used directly. If it is a function it will be called after the subject
is resolved and should return a string. If it is a table you may provide one of
the following keys with appropriate values:

- `motion = "ap"` Use this motion from the current cursor to get the range.

eg. specifying `range = '%'` will make the substitution run over the
whole file. See `:h [range]` for all the possible values here.

eg. `lua require('substitute.range').operator({ range = { motion = 'ap' } })`
will select around paragraph as range of substitution.

You can combine `subject` and `range` :
`lua require('substitute.range').operator({ subject = { motion='iw' }, range = { motion = 'ap' } })`
will prepare substitution for inner word around paragraph.

#### `range.motion1` _DEPRECATED_

Default : `false`

This is option deprecated and equivalent to providing `subject.motion`.

#### `range.motion2` _DEPRECATED_

Default : `false`

This option is deprecated and equivalent to `range.motion`

#### `range.register`

Default : `nil`

This will use the content of this register as replacement value.

eg. `lua require('substitute.range').operator({ register = 'a' })` will use `"a`
register content as replacement.

### 🤝 Integration

<details>
<summary><b>tpope/vim-abolish</b></summary>

You can use [tpope/vim-abolish](https://github.com/tpope/vim-abolish) substitution by default.

```lua
require("substitute").setup({
  range = {
    prefix = "S",
  }
})
```

</details>

## 🔀 Exchange operator

This operator allows to quickly exchange text inside a buffer.

Eg. To exchange two words, place your cursor on the first word and type `sxiw`.
Then move to the second word and type `sxiw` again.

Note: the {motion} used in the first and second use of `sx` don't have to be the same.
Note 2: this is dot-repeatable, so you can use `.` instead of `sxiw` for the second word.

You can select a whole line using the `line` function (`sxx` in the example below).

Because this operator has to be invoked twice to change the document, if you
change your mind after invoking the operator once, you can cancel you selection
using `<Esc>` key or the `cancel` function (mapped to `sxc` in the example below).

```lua
vim.keymap.set("n", "sx", require('substitute.exchange').operator, { noremap = true })
vim.keymap.set("n", "sxx", require('substitute.exchange').line, { noremap = true })
vim.keymap.set("x", "X", require('substitute.exchange').visual, { noremap = true })
vim.keymap.set("n", "sxc", require('substitute.exchange').cancel, { noremap = true })
```

### ⚙️ Configuration

#### `exchange.motion`

Default : `nil`

This will use this motion for exchange.

eg. `lua require('substitute.exchange').operator({ motion = 'ap' })` will select
around paragraph as range of exchange.

#### `exchange.use_esc_to_cancel`

Default : `true`

If `true`, you can use the `<Esc>` key to cancel exchange selection. If set to
false, consider map the cancel function:

```lua
vim.keymap.set("n", "sxc", require('substitute.exchange').cancel, { noremap = true })
```

### `exchange.preserve_cursor_position`

Default : `false`

If `true`, the cursor position will be preserved when performing an exchange.

## 🎨 Colors

| Description                           | Group              | Default        |
| ------------------------------------- | ------------------ | -------------- |
| Selected range for range substitution | SubstituteRange    | link to Search |
| Selected text for exchange            | SubstituteExchange | link to Search |

## 🎉 Credits

This plugin is a lua version of [svermeulen/vim-subversive](https://github.com/svermeulen/vim-subversive) and
[tommcdo/vim-exchange](https://github.com/tommcdo/vim-exchange) awesome plugins.

Thanks to [m00qek lua plugin template](https://github.com/m00qek/plugin-template.nvim).
