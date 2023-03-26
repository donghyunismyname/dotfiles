function! myspacevim#before() abort

endfunction



function! myspacevim#after() abort



"Coc 
call coc#config('coc.preferences', {
			\ "autoTrigger": "always",
			\ "maxCompleteItemCount": 10,
			\ "codeLens.enable": 1,
			\ "diagnostic.virtualText": 1,
			\})

call coc#config("suggest.noselect", 1)

let s:coc_extensions = [
			\ 'coc-dictionary',
			\ 'coc-json',
			\ 'coc-ultisnips',
			\ 'coc-tag',
            \ 'coc-clangd',
            \ 'coc-pyright',
            \ 'coc-jedi',
			\]

for extension in s:coc_extensions
	call coc#add_extension(extension)
endfor




set number relativenumber  "line number on the left
set autoindent      "autoindent
set hlsearch        "highlight search with / or ?
set ignorecase      "ignore case for search
set incsearch       "show search result for input character
set showmatch       "highlight matching brackets
set mouse=a         "allow mouse
set ts=4            "tap size
set sw=4            "shift width for use with >, <, or =
set expandtab       "spaces instead of tabs; `:retab` to change taps to spaces
set sts=4           "make spaces feel like tabs (like deleting)
set colorcolumn=80  "show vertical line at column 80
set nowrap          "no wraparound trailing characters
set scrolloff=99999 "put cursor always in center
set list            "make whitespaces visible
"set listchars=tab:>-,trail:~,extends:>,precedes:<
set listchars=tab:»\ ,trail:·,extends:>,precedes:<

"set cursorline
"set cursorcolumn
"autocmd insertenter * set cursorline
"autocmd insertleave * set cursorline
"autocmd insertenter * set cursorcolumn
"autocmd insertleave * set cursorcolumn


"keymaps
inoremap jk <esc>
nnoremap H 5j
"nnoremap J 5j
"nnoremap K 5k
nnoremap L 5k
vnoremap H 5j
"jkvnoremap J 5j
"vnoremap K 5k
vnoremap L 5k

endfunction
