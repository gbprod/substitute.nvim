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
  },
}
```

More details on these options is available in the sections below corresponding to the different features.

## 🔂 Substitute operator

It contains no default mappings and will have no effect until you add your own maps to it.

```lua
-- Lua
vim.keymap.set("n", "s", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })
vim.keymap.set("n", "ss", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
vim.keymap.set("n", "S", "<cmd>lua require('substitute').eol()<cr>", { noremap = true })
vim.keymap.set("x", "s", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })
```

Then you can then execute `s<motion>` to substitute the text object provided by the motion with the contents of
the default register (or an explicit register if provided). For example, you could execute siw to replace the
current word under the cursor with the current yank, or sip to replace the paragraph, etc.

This action is dot-repeatable.

Note: in this case you will be shadowing the change character key `s` so you will have to use the longer form `cl`.

Each functions (`operator`, `line`, `eol` and `visual`) are configurable:

```lua
lua require('substitute').operator({
  count = 1,      -- number of substitutions
  register = "a", -- register used for substitution
  motion = "iw",  -- only available for `operator`, this will automatically use
                  -- this operator for substitution instead of asking for.
})
```

### ⚙️ Configuration

#### `on_substitute`

Default : `nil`

Function that will be called each times a substitution is made. This function takes a `param` argument that contains the `register` used for substitution.

#### `yank_substituted_text`

Default : `false`

If `true`, when performing a substitution, substitued text is pushed into the default register.

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
vim.keymap.set("x", "p", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })
vim.keymap.set("x", "P", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })
```

</details>

## 🔁 Substitute over range motion

Another operator provided allows specifying both the text to replace and the line range over which to apply the
change by using multiple consecutive motions.

```lua
vim.keymap.set("n", "<leader>s", "<cmd>lua require('substitute.range').operator()<cr>", { noremap = true })
vim.keymap.set("x", "<leader>s", "<cmd>lua require('substitute.range').visual()<cr>", { noremap = true })
vim.keymap.set("n", "<leader>ss", "<cmd>lua require('substitute.range').word()<cr>", { noremap = true })
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
vim.keymap.set("n", "<leader>S", "<cmd>lua require('substitute.range').operator({ prefix = 'S' })<cr>", { noremap = true })
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

This will capture substitued text as you can use `\1` to quickly reuse it.

#### `range.motion1`

Default : `false`

This will use this motion for the first motion of range substitution.

eg. `lua require('substitute.range').operator({ motion1 = 'iW' })` will select
inner WORD as subject of substitution.

#### `range.motion2`

Default : `false`

This will use this motion for the second motion of range substitution.

eg. `lua require('substitute.range').operator({ motion2 = 'ap' })` will select
around paragraph as range of substitution.

You can combine `motion1` and `motion2` :
`lua require('substitute.range').operator({ motion1='iw', motion2 = 'ap' })`
will prepare substitution for inner word around paragraph.

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
vim.keymap.set("n", "sx", "<cmd>lua require('substitute.exchange').operator()<cr>", { noremap = true })
vim.keymap.set("n", "sxx", "<cmd>lua require('substitute.exchange').line()<cr>", { noremap = true })
vim.keymap.set("x", "X", "<cmd>lua require('substitute.exchange').visual()<cr>", { noremap = true })
vim.keymap.set("n", "sxc", "<cmd>lua require('substitute.exchange').cancel()<cr>", { noremap = true })
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
vim.keymap.set("n", "sxc", "<cmd>lua require('substitute.exchange').cancel()<cr>", { noremap = true })
```

## 🎨 Colors

| Description                           | Group              | Default        |
| ------------------------------------- | ------------------ | -------------- |
| Selected range for range substitution | SubstituteRange    | link to Search |
| Selected text for exchange            | SubstituteExchange | link to Search |

## 🎉 Credits

This plugin is a lua version of [svermeulen/vim-subversive](https://github.com/svermeulen/vim-subversive) and
[tommcdo/vim-exchange](https://github.com/tommcdo/vim-exchange) awesome plugins.

Thanks to [m00qek lua plugin template](https://github.com/m00qek/plugin-template.nvim).
