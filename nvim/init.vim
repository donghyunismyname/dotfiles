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


" TODO: add appropriate key map
Plug 'kqito/vim-easy-replace'


" Plug 'SirVer/ultisnips'
" Plug 'honza/vim-snippets'
" Plug 'jayli/vim-easycomplete'
" noremap gr :EasyCompleteReference<CR>
" noremap gd :EasyCompleteGotoDefinition<CR>
" noremap rn :EasyCompleteRename<CR>
" noremap gb :BackToOriginalBuffer<CR>


call plug#end()
lua require('hop').setup()


" highlight yanked text
au TextYankPost * silent!
\ lua vim.highlight.on_yank { higroup="IncSearch", timeout=1000 }




