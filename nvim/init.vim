" config from .vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc


" vim-plug: Vim Plugin Manager
call plug#begin()
Plug 'ggandor/leap.nvim'
call plug#end()

" plugin: leap.nvim
lua require('leap').add_default_mappings()


" lua require('hop').setup()
