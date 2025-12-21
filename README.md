# dotfiles
An attempt to create my own dotfiles.
`zsh`, `vim`, and `tmux` combine together to create an awesome
development environment.

(no, modern GUI-based AI-assisted editors are better)


## Recommended Fonts
- (DroidSansMono Nerd Font) https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/DroidSansMNerdFontMono-Regular.otf
- (D2Coding) https://github.com/naver/d2codingfont
- `sudo apt install fonts-jetbrains-mono`
- `brew install --cask font-jetbrains-mono-nerd-font`


## Dependency (install on your own)
Most likely you can use `apt` or `brew` to install:
- zsh
- tree (show directory stuructures as a tree)
- bat (like cat but fancy)
- tmux
- ripgrep
- fd (try `fd` or `fd-find` for installation)
- neovim
- emacs


## Dependency (install script provided)
- oh-my-zsh
- fzf
- cdhist
- diff-so-fancy (make git diff fancy)


## Installation
Run the installation script inside project diretory
```
dotfiles$ sh install-dependency.sh
dotfiles$ sh install-symlink.sh
dotfiles$ sh configure-git.sh
```
It's likely that things do not work.
In that case, please install manually following the scripts.


## Install Latest Neovim
```
sudo apt-get remove neovim -y

sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update -y
sudo apt-get install neovim -y
```



## Troubleshooting
```
zsh | (anon):12: character not in range
```
https://gist.github.com/jadia/1f4c2190730ef646d41823b6a6c30926

Special characters break on tmux
https://askubuntu.com/questions/410048/utf-8-character-not-showing-properly-in-tmux

Neovim plugins not installed well
https://www.reddit.com/r/neovim/comments/i65pwd/no_python3_provider_found_run_checkhealth_provider/





## Inspired by
https://github.com/wookayin/dotfiles/


