" config from .vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc


" highlight yanked text
au TextYankPost * silent!
\ lua vim.highlight.on_yank { higroup="IncSearch", timeout=200 }


" vim-plug: Vim Plugin Manager
call plug#begin()

Plug 'ggandor/lightspeed.nvim'


" Plug 'rlane/pounce.nvim'
" map s <cmd>Pounce<cr>
" map S <cmd>PounceRepeat<cr>


" Plug 'phaazon/hop.nvim'
" map <cr> <cmd>HopWordMW<cr>


" This plugin in integrated in Vim
" TODO: add appropriate key map
" Plug 'kqito/vim-easy-replace'
" <leader>ra launch easy-replace
" <leader>rc use word under current cursor


" Plug 'michaeljsmith/vim-indent-object'


" Plug 'bkad/CamelCaseMotion'
" let g:camelcasemotion_key = '<leader>'


" Plug 'SirVer/ultisnips'
" Plug 'jayli/vim-easycomplete'
" noremap gr :EasyCompleteReference<CR>
" noremap gd :EasyCompleteGotoDefinition<CR>
" noremap rn :EasyCompleteRename<CR>
" noremap gb :BackToOriginalBuffer<CR>
" let g:easycomplete_diagnostics_enable = 1
" let g:easycomplete_signature_enable = 1
" let g:easycomplete_tabnine_enable = 1
" let g:easycomplete_cursor_word_hl = 1
" let g:easycomplete_nerd_font = 1


noremap gr :ALEFindReferences<cr>
noremap gd :ALEGoToDefinition<cr>
noremap gh :ALEHover<cr>
noremap ? :ALESymbolSearch<space>
let g:ale_completion_enabled = 1
set omnifunc=ale#completion#OmniFunc
Plug 'dense-analysis/ale'


call plug#end()

