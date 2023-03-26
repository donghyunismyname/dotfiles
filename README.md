# dotfiles
An attempt to create my own dotfiles.
zsh, vim, and tmux combine together to create an awesome
development environment.


## Recommended Fonts
- https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/SourceCodePro/Regular/complete/Sauce%20Code%20Pro%20Nerd%20Font%20Complete.ttf
- https://github.com/naver/d2codingfont


## Dependency (install on your own)
Mostly like you can use `apt` or `brew` to install them.
- zsh
- tree (show directory stuructures as a tree)
- bat (like cat but fancy)
- tmux
- neovim


## Dependency (install script provided)
- oh-my-zsh
- fzf
- cdhist
- spacevim


## Installation
Run the installation script:
```
sh install_dependency.sh
sh_install_symlink.sh
```
It's likely that things do not work.
In that case, please install manually by following the scripts.



## Troubleshooting
```
zsh | characters not in range
```
https://gist.github.com/jadia/1f4c2190730ef646d41823b6a6c30926

Special characters break on tmux
https://askubuntu.com/questions/410048/utf-8-character-not-showing-properly-in-tmux

Neovim plugins is not installed well
https://www.reddit.com/r/neovim/comments/i65pwd/no_python3_provider_found_run_checkhealth_provider/



## Inspired by
https://github.com/wookayin/dotfiles/


