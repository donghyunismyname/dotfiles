" config from .vimrc
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc

colorscheme jellybeans


" highlight yanked text
au TextYankPost * silent!
\ lua vim.highlight.on_yank { higroup="IncSearch", timeout=500 }

" lua require("lsp")


" vim-plug: Vim Plugin Manager
call plug#begin()

Plug 'folke/flash.nvim'


" Plug 'rlane/pounce.nvim'
" map s <cmd>Pounce<cr>
" map S <cmd>PounceRepeat<cr>



" This plugin in integrated in Vim
" TODO: add appropriate key map
" Plug 'kqito/vim-easy-replace'
" <leader>ra launch easy-replace
" <leader>rc use word under current cursor


" Plug 'michaeljsmith/vim-indent-object'



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

":LspInstallServer
"Plug 'prabirshrestha/vim-lsp'
"Plug 'mattn/vim-lsp-settings'
" Plug 'prabirshrestha/asyncomplete.vim'
" Plug 'prabirshrestha/asyncomplete-lsp.vim'
"let g:lsp_diagnostics_enabled = 0
"if executable('pylsp')
"    " pip install python-lsp-server
"    au User lsp_setup call lsp#register_server({
"        \ 'name': 'pylsp',
"        \ 'cmd': {server_info->['pylsp']},
"        \ 'allowlist': ['python'],
"        \ })
"endif

"function! s:on_lsp_buffer_enabled() abort
"    setlocal omnifunc=lsp#complete
"    setlocal signcolumn=yes
"    if exists('+tagfunc') | setlocal tagfunc=lsp#tagfunc | endif
"    nmap <buffer> gd <plug>(lsp-definition)
"    nmap <buffer> gs <plug>(lsp-document-symbol-search)
"    nmap <buffer> gS <plug>(lsp-workspace-symbol-search)
"    nmap <buffer> gr <plug>(lsp-references)
"    nmap <buffer> gi <plug>(lsp-implementation)
"    nmap <buffer> gt <plug>(lsp-type-definition)
"    nmap <buffer> <leader>rn <plug>(lsp-rename)
"    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
"    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
"    nmap <buffer> K <plug>(lsp-hover)
"    " nnoremap <buffer> <expr><c-f> lsp#scroll(+4)
"    " nnoremap <buffer> <expr><c-d> lsp#scroll(-4)

"    let g:lsp_format_sync_timeout = 1000
"    autocmd! BufWritePre *.rs,*.go call execute('LspDocumentFormatSync')

"    " refer to doc to add more commands
"endfunction

"augroup lsp_install
"    au!
"    " call s:on_lsp_buffer_enabled only for languages that has the server registered.
"    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
"augroup END


call plug#end()

