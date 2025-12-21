# dotfiles
my own dotfiles

`zsh`, `vim`, and `tmux` combine together to create an awesome
development environment.

(no, modern GUI-based AI-assisted editors are better)


## Fonts
- (DroidSansMono Nerd Font) https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/DroidSansMNerdFontMono-Regular.otf
- (D2Coding) https://github.com/naver/d2codingfont
- `sudo apt install fonts-jetbrains-mono`
- `brew install font-jetbrains-mono`


## Dependency (install on your own)

| Tool | Description | brew | apt |
|------|-------------|------|-----|
| zsh | Shell | `brew install zsh` | `sudo apt install zsh` |
| tmux | Terminal multiplexer | `brew install tmux` | `sudo apt install tmux` |
| neovim | Editor | `brew install neovim` | `sudo apt install neovim` |
| bat | Better cat | `brew install bat` | `sudo apt install bat` |
| ripgrep | Better grep | `brew install ripgrep` | `sudo apt install ripgrep` |
| fd | Better find | `brew install fd` | `sudo apt install fd-find` |
| delta | Better git diff | `brew install git-delta` | `sudo apt install git-delta` |
| btop | Better htop | `brew install btop` | `sudo apt install btop` |
| dust | Better du | `brew install dust` | `sudo apt install dust` |
| duf | Better df | `brew install duf` | `sudo apt install duf` |
| procs | Better ps | `brew install procs` | `sudo apt install procs` |
| eza | Better ls | `brew install eza` | `sudo apt install eza` |
| zoxide | Better cd | `brew install zoxide` | `sudo apt install zoxide` |
| lazygit | Git TUI | `brew install lazygit` | `sudo apt install lazygit` |
| lazydocker | Docker TUI | `brew install lazydocker` | `sudo apt install lazydocker` |



## Dependency (install script provided)
- oh-my-zsh
- fzf
- cdhist



## Installation
Run the scripts inside project diretory.

```sh
dotfiles$ sh install-dependency.sh
dotfiles$ sh install-symlink.sh
```

But things may not work.




## Latest Neovim
```sh
sudo apt-get remove neovim -y

sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update -y
sudo apt-get install neovim -y
```



## Troubleshooting
```sh
zsh | (anon):12: character not in range
```
https://gist.github.com/jadia/1f4c2190730ef646d41823b6a6c30926

Special characters break on tmux
https://askubuntu.com/questions/410048/utf-8-character-not-showing-properly-in-tmux

Neovim plugins not installed properly
https://www.reddit.com/r/neovim/comments/i65pwd/no_python3_provider_found_run_checkhealth_provider/




## Inspired by
https://github.com/wookayin/dotfiles/


