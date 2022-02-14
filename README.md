# substitute.nvim

[![Integration](https://github.com/gbprod/substitute.nvim/actions/workflows/integration.yml/badge.svg)](https://github.com/gbprod/substitute.nvim/actions/workflows/integration.yml)

`substitute.nvim` aim is to provide new operator motions to make it very easy to perform quick substitutions and exchange.

If you are familiar with [svermeulen/vim-subversive](https://github.com/svermeulen/vim-subversive) and
[tommcdo/vim-exchange](https://github.com/tommcdo/vim-exchange), this plugin does almost the same but
rewritten in `lua` (and I hope this will be more maintainable, readable and efficient).

[See this plugin in action](DEMO.md)

##### Table of content

- [Install](#install)
- [Substitute operator](#substitute-operator)
- [Substitute over range motion](#substitute-over-range-motion)
- [Exchange operator](#exchange-operator)
- [Credits](#credits)

## Install

Requires neovim > 0.6.0.

Using [packer](https://github.com/wbthomason/packer.nvim):

```lua
use({
  "gbprod/substitute.nvim",
  config = function()
    require("substitute").setup()
  end
})
```

## Substitute operator

It contains no default mappings and will have no effect until you add your own maps to it.

```lua
vim.api.nvim_set_keymap("n", "s", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "ss", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "S", "<cmd>lua require('substitute').eol()<cr>", { noremap = true })
vim.api.nvim_set_keymap("x", "s", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })
```

Or

```viml
nnoremap s <cmd>lua require('substitute').operator()<cr>
nnoremap ss <cmd>lua require('substitute').line()<cr>
nnoremap S <cmd>lua require('substitute').eol()<cr>
xnoremap s <cmd>lua require('substitute').visual()<cr>
```

Then you can then execute `s<motion>` to substitute the text object provided by the motion with the contents of
the default register (or an explicit register if provided). For example, you could execute siw to replace the
current word under the cursor with the current yank, or sip to replace the paragraph, etc.

This action is dot-repeatable.

Note: in this case you will be shadowing the change character key `s` so you will have to use the longer form `cl`.

### Configuration

#### `on_substitute`

Default : `nil`

Function that will be called each times a substitution is made. This function takes a `param` argument that contains the `register` used for substitution.

#### `yank_substitued_text`

Default : `false`

If `true`, when performing a substitution, substitued text is pushed into the default register.

### Integration

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
vim.api.nvim_set_keymap("x", "p", "<cmd>lua require('substitute').visual()<cr>", {})
vim.api.nvim_set_keymap("x", "P", "<cmd>lua require('substitute').visual()<cr>", {})
```

or

```viml
xmap p <cmd>lua require('substitute').visual()<cr>
xmap P <cmd>lua require('substitute').visual()<cr>
```

</details>

## Substitute over range motion

Another operator provided allows specifying both the text to replace and the line range over which to apply the
change by using multiple consecutive motions.

```lua
vim.api.nvim_set_keymap("n", "<leader>s", "<cmd>lua require('substitute.range').operator()<cr>", { noremap = true })
vim.api.nvim_set_keymap("x", "<leader>s", "<cmd>lua require('substitute.range').visual()<cr>", {})
vim.api.nvim_set_keymap("n", "<leader>ss", "<cmd>lua require('substitute.range').word()<cr>", {})
```

or

```viml
nmap <leader>s <cmd>lua require('substitute.range').operator()<cr>
xmap <leader>s <cmd>lua require('substitute.range').visual()<cr>
nmap <leader>ss <cmd>lua require('substitute.range').word()<cr>
```

After adding this map, if you execute `<leader>s<motion1><motion2>` then the command line will be filled with a
substitute command that allow to replace the text given by `motion1` by the text will enter in the command line for each
line provided by `motion2`.

Alternatively, we can also select `motion1` in visual mode and then hit `<leader>s<motion2>` for the same effect.

For convenience, `<leader>ss<motion2>` can be used to select complete word under the cursor as motion1 (complete word
means that `complete_word` options is override to `true` so is different from <leader>siwip which will not require that
there be word boundaries on each match).

You can override any default configuration (described later) by passing this to the operator function. By example,
this will use `S` as prefix of the substitution command (and use [tpope/vim-abolish](https://github.com/tpope/vim-abolish)):

```viml
nmap <leader>S <cmd>lua require('substitute.range').operator({ prefix = 'S' })<cr>
```

### Configuration

#### `range.prefix`

Default : `s`

Substitution command that will be used (set it to `S` to use [tpope/vim-abolish](https://github.com/tpope/vim-abolish) substitution by default).

#### `range.prompt_current_text`

Default : `false`

Substitution command replace part will be set to the current text. Eg. instead of `s/pattern//g` you will have `s/pattern/pattern/g`.

#### `range.confirm`

Default : `false`

Will ask for confirmation for each substitutions.

#### `range.complete_word`

Default : `false`

Will require that there be word boundaries on each match (eg: `\<word\>` instead of `word`).

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

### Integration

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

### Configuration

#### `range.prefix`

Default : `s`

Function that will be called each times a substitution is made. This function takes a `param` argument that contains the `register` used for substitution.

## Exchange operator

This operator allows to quickly exchange text inside a buffer.

Eg. To exchange two words, place your cursor on the first word and type `sxiw`. Then move to the second word and type
`sxiw` again.
Note: the {motion} used in the first and second use of `sx` don't have to be the same.
Note 2: this is dot-repeatable, so you can use `.` instead of `sxiw` for the second word.

```lua
vim.api.nvim_set_keymap("n", "sx", "<cmd>lua require('substitute.exchange').operator()<cr>", { noremap = true })
vim.api.nvim_set_keymap("n", "sxx", "<cmd>lua require('substitute.exchange').line()<cr>", { noremap = true })
vim.api.nvim_set_keymap("x", "X", "<cmd>lua require('substitute.exchange').visual()<cr>")
```

or

```viml
nmap sx <cmd>lua require('substitute.exchange').operator()<cr>
nmap sxx <cmd>lua require('substitute.exchange').line()<cr>
xmap X <cmd>lua require('substitute.exchange').visual()<cr>
```

#### `exchange.motion`

Default : `nil`

This will use this motion for exchange.

eg. `lua require('substitute.exchange').operator({ motion = 'ap' })` will select
around paragraph as range of exchange.

## Credits

This plugin is a lua version of [svermeulen/vim-subversive](https://github.com/svermeulen/vim-subversive) and
[tommcdo/vim-exchange](https://github.com/tommcdo/vim-exchange) awesome plugins.

Thanks to [m00qek lua plugin template](https://github.com/m00qek/plugin-template.nvim).
