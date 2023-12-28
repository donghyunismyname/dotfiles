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



## Useful Plugins
- Vim
- Jumpy2 (compatible with Vim)
- GitHub Copilot



## Useful Default Bindings
```
<c-`>: toggle terminal
<c-b>: toggle primary side bar
<alt-z>: toggle word wrap mode
<command pallette> toggle vim node

<c-e>: go to file
<c-E>: open explorer

<c-O>: outline movement

<c-f>: find
<c-F>: open search

<c-G>: source control

<f4>: next item in search
<shift-f4>: previous item in search

<f12>: go to definition
<shift-f12>: go to references

<f8>: go to next problem
<shift-f8> go to previous problem

block + <alt-shift-i>: multiple cursors at the end of each line
<alt+shift+up> / <alt+shift+down>
```



## Custom Bindings

```
<c-shift-t>: open new terminal in editor area (<c-w> to close)

<c-m>: multiselect (originally <c-d>, also works by gb)

<c-[hjkl]>: navigate
<c-shift-[hjkl]>: split editor to desired direction

<c-enter>: zoom in/out

<c-[pn]> or <c-[kj]>: navigate to previous/next item in quick open menu
<c-[,.]>: navigate to previous/next tab (previously <c-pageup/down>)

(panelFocus) <c-[hl]>: preivous/next panel view
(panelFocus) <c-[kj]>: previous/next terminal group
```


## Custom VSCodeVim Settings
```
- inoremap jk <esc>
- nnoremap > >>llll
- vnoremap > >gvllll
- noremap L $
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


## Glassit
Make window transparent
```
<c-shift-z>: make more transparent
<c-shift-c>: make more opaque
```



