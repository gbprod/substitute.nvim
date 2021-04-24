set rtp+=.
set rtp+=vendor/plenary.nvim/

runtime plugin/plenary.vim
runtime ../plugin/substitute.vim

lua require('plenary.busted')
