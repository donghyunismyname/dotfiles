function! myspacevim#before() abort

endfunction






function! myspacevim#after() abort

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
set cursorline
set cursorcolumn

"keymaps
"H works as <home>
"L works as <end>
inoremap jk <esc>
nnoremap H 0
nnoremap J 5j
nnoremap K 5k
nnoremap L $
vnoremap H 0
vnoremap J 5j
vnoremap K 5k
vnoremap L $

endfunction
