# VSCode configuration files

## Installation
Put them into `/your/project/root/.vscode/` for project-wise scope,
or one of the following directories for user-wise scope.

```
# Windows
/Users/{username}/AppData/Roaming/Code/User/

# Linux

# MacOS
```



## Must-have Plugins
- Vim
- Jumpy2 (compatible with Vim)
- GitHub Copilot



## Useful Default Bindings
```
<c-w>: close editor
<c-W>: (disabled) close vscode
<c-W>: (custom) reopen closed editor

<c-`>: toggle terminal
<c-b>: toggle primary side bar
<command pallette> toggle vim node

<c-e>: go to file
<c-E>: open explorer

<c-f>: find
<c-F>: open search

<c-G>: source control

<f4>: next item in search
<shift-f4>: previous item in search

<f12>: go to definition
<shift-f12>: go to references

<f8>: go to next problem
<shift-f8> go to previous problem
```



## Custom Bindings

```
<c-space>n: trigger suggestion
<c-t>: open new terminal in editor area (<c-w> to close)
<c-m>: multiselect (originally <c-d>, also works by gb)

<c-[hjkl]>: move among editor groups
<c-space>[hjkl]: split editor to desired direction

<c-space><c-space>: zoom in/out
<c-space><enter>: move focus to panel/back to editor

<c-[pn]> or <c-[kj]>: navigate to previous/next item in quick open menu
<c-[,.]>: navigate to previous/next tab (previously <c-pageup/down>)

(panelFocus) <c-[hl]>: preivous/next panel view
(panelFocus) <c-[kj]>: previous/next terminal group
```


## Custom VSCodeVim Settings
```
- inoremap jk <esc>
- nnoremap > >>
- vnoremap > >gv
- Yanked text is blinked yellow
- Use system clipboard for yank and paste
- For x, d, c, internal clipboard is used
- Yanking does not lose visual mode
- Pasting does not lose system clipboard
```


## VSCodeVim Tricks
```
https://dev.to/ansonh/10-vs-code-vim-tricks-to-boost-your-productivity-1b0n


gd: go to definition
gi: go to implementation
gt: go to type definition
gpd: peek definition
gpi: peek implementation
gpt: peek type definition
gr: go to reference
gh: hover cursor
gq: quick fix

gb: multiselect
```


