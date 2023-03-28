function! myspacevim#before() abort

endfunction




function! myspacevim#after() abort

filetype plugin on

" comment toggling with https://github.com/tpope/vim-commentary
" must be resursive
nmap - gcc
vmap - gc





function! Trim(input_string)
    return substitute(a:input_string, '^\s*\(.\{-}\)\s*$', '\1', '')
endfunction

function! s:get_git_dir(path)
  let curr = fnamemodify(expand(a:path), ':p')
  if empty(curr)   " empty buffer, etc.: fall back to current dir
    let curr = getcwd()
  endif
  try
    return FugitiveExtractGitDir(curr)
  catch /E117/  " Unknown function: maybe incompatible fugitive
    return fugitive#extract_git_dir(curr)
  endtry
endfunction

" Command :F (FzfSmart)
function! FzfSmart(path) abort
  " If args are given (e.g. :F <args>), run :Files <args>
  let l:path = Trim(a:path)
  if !empty(l:path)
    let l:path = expand(l:path)
    if !isdirectory(l:path)   " for a file, the directory that contains it
      if filereadable(l:path)
        let l:path = fnamemodify(l:path, ":h")
      else  " does not exist, error
        echohl WarningMsg | call Echom('Does not exist: ' . l:path) | echohl NONE | return 0
      endif
    endif
  endif

  " (1) If a FZF tree/explorer is shown with no argument,
  " invoke :Files (with preview) rather than :GFiles
  if empty(l:path) && index(['nerdtree'], &filetype) >= 0
    let l:target_path = b:NERDTree.root.path._str()
    " if the current buffer is the pinned on in the tab (vim-nerdtree-tabs),
    " let fzf open files in another window. Otherwise, open in the current window.
    if exists('t:NERDTreeBufName') && bufname('%') == t:NERDTreeBufName
      wincmd w   " we need to move the focus outside nerdtree
    endif
    call fzf#vim#files(l:target_path, fzf#vim#with_preview())
    return 1
  endif

  " (2) If the given path (or CWD) is in a git repo,
  " invoke :GFiles (plus untracked files)
  let l:git_dir = s:get_git_dir(!empty(l:path) ? l:path : '%')
  if ! empty(l:git_dir)
    let l:old_cwd = getcwd()
    execute ':tcd ' . l:git_dir . '/..'
    echon ':GFiles (' | echohl Directory | echon getcwd() | echohl NONE | echon ')' | echon '    '
    GFiles -c -o --exclude-standard
    execute ':tcd ' . l:old_cwd
    return 2

  " (3) not in git repo, invoke :Files <args> by fallback
  else
    execute ':Files ' . l:path
    return 3
  endif
endfunction

" :F is a shortcut for :GFiles or :FZF
command! -complete=dir -nargs=* F        call FzfSmart(<q-args>)

" Invoke F (FZF) Using Ctrl-P
" nmap <C-P> :bw<cr>:F<CR>
nmap <C-P> :F<CR>




"Coc 
"prevent default behavior for 
inoremap <cr> <cr>

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
            \ 'coc-highlight',
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
set nostartofline   "keep column position when c-u or c-d

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

nnoremap zh :vs<cr>
nnoremap zj :sp<cr><c-w>j
nnoremap zk :sp<cr>
nnoremap zl :vs<cr><c-w>l
nnoremap zd :wq<cr>






endfunction
