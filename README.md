# dotfiles

Personal dotfiles for `zsh`, `vim`, `tmux`, and modern CLI tools.

(no, modern GUI-based AI-assisted editors are better)

(terminal utilities are still useful, though...)

## Quick Start

### macOS

```sh
sh install-macos.sh
sh install-shell.sh
sh install-symlinks.sh
```

### Ubuntu

```sh
sh install-ubuntu.sh
sh install-shell.sh
sh install-symlinks.sh
```

## Fonts

Install on your **local machine** (where your terminal app runs), not on remote servers.

| Font                                                                                                                                       | Install                                                                          |
| ------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------- |
| [DroidSansMono Nerd Font](https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/DroidSansMono/DroidSansMNerdFontMono-Regular.otf) | Download                                                                         |
| [D2Coding](https://github.com/naver/d2codingfont)                                                                                             | Download                                                                         |
| JetBrains Mono                                                                                                                             | `brew install font-jetbrains-mono` / `sudo apt install fonts-jetbrains-mono` |

## CLI Tools

| Tool       | Description           |
| ---------- | --------------------- |
| zsh        | Shell                 |
| tmux       | Terminal multiplexer  |
| neovim     | Editor                |
| bat        | Better `cat`        |
| ripgrep    | Better `grep`       |
| fd         | Better `find`       |
| delta      | Better `git diff`   |
| eza        | Better `ls`         |
| zoxide     | Better `cd`         |
| btop       | Better `htop`       |
| dust       | Better `du`         |
| duf        | Better `df`         |
| procs      | Better `ps`         |
| witr       | Why is this running?  |
| lazygit    | Git TUI               |
| lazydocker | Docker TUI            |
| tokei      | Code line counter     |
| miniserve  | Simple HTTP server    |
| fzf        | Fuzzy finder          |
| uv         | Python package manager |
| cdhist     | Better `cd` history |
| oh-my-zsh  | Zsh framework         |

## Troubleshooting

### Latest Neovim on Ubuntu

```sh
sudo apt-get remove neovim -y
sudo add-apt-repository ppa:neovim-ppa/stable
sudo apt-get update -y
sudo apt-get install neovim -y
```

### zsh: character not in range

https://gist.github.com/jadia/1f4c2190730ef646d41823b6a6c30926

### Special characters break on tmux

https://askubuntu.com/questions/410048/utf-8-character-not-showing-properly-in-tmux

### Neovim: No Python3 provider

https://www.reddit.com/r/neovim/comments/i65pwd/no_python3_provider_found_run_checkhealth_provider/

## Credits

Inspired by https://github.com/wookayin/dotfiles/
