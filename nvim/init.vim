" config from .vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc


" vim-plug: Vim Plugin Manager
call plug#begin()


Plug 'rlane/pounce.nvim'
map s <cmd>Pounce<cr>
map S <cmd>PounceRepeat<cr>


Plug 'phaazon/hop.nvim'
map <cr> <cmd>HopWordMW<cr>


" ultisnips
" vim-easycomplete
" vim-snippets


call plug#end()







lua require('hop').setup()
