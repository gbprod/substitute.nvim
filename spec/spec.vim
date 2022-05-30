set rtp+=.
set rtp+=vendor/plenary.nvim/

runtime plugin/plenary.vim
runtime ../plugin/substitute.vim

lua require('plenary.busted')

lua vim.keymap.set("n", "ss", "<cmd>lua require('substitute').line()<cr>", { noremap = true })
lua vim.keymap.set("n", "S", "<cmd>lua require('substitute').eol()<cr>", { noremap = true })
lua vim.keymap.set("n", "s", "<cmd>lua require('substitute').operator()<cr>", { noremap = true })
lua vim.keymap.set("x", "s", "<cmd>lua require('substitute').visual()<cr>", { noremap = true })

lua vim.keymap.set("n", "<leader>s", "<cmd>lua require('substitute.range').operator()<cr>", { noremap = true, })

lua vim.keymap.set("n", "sx", "<cmd>lua require('substitute.exchange').operator()<cr>", { noremap = true })
lua vim.keymap.set("x", "X", "<cmd>lua require('substitute.exchange').visual()<cr>", { noremap = true })
