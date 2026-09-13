# dotfiles

Personal dotfiles for `zsh`, `vim`, `tmux`, and modern CLI tools.

(no, modern GUI-based AI-assisted editors are better)

(terminal utilities are still useful, though...)

## Quick Start

```sh
sh install.sh           # runs the three scripts below in order
sh install.sh --system  # ... plus install-system.sh
```

Or run them individually:

```sh
sh install-tools.sh   # CLI tools (uses Homebrew)
sh install-shell.sh   # zsh, plugins, fzf keybindings
sh install-configs.sh # Link vim, nvim, tmux, yazi, zshenv; stub ~/.zshrc and ~/.gitconfig
sh install-system.sh    # Linux servers only: sysstat, atop, earlyoom, sshd guard, agent memory cap (sudo)
```

## Fonts

Install a [Nerd Font](https://www.nerdfonts.com/font-downloads) on your **local machine** (where your terminal app runs), not on remote servers.

| Font | Download | Homebrew (macOS) |
| ---- | -------- | ---------------- |
| DroidSansM Nerd Font (recommended) | [DroidSansMono.zip](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/DroidSansMono.zip) | `brew install --cask font-droid-sans-mono-nerd-font` |
| D2Coding Nerd Font (Korean) | [D2Coding.zip](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/D2Coding.zip) · [original](https://github.com/naver/d2codingfont/releases) | `brew install --cask font-d2coding-nerd-font` |
| JetBrainsMono Nerd Font | [JetBrainsMono.zip](https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip) | `brew install --cask font-jetbrains-mono-nerd-font` |

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
| ncdu       | Interactive `du`    |
| duf        | Better `df`         |
| procs      | Better `ps`         |
| witr       | Why is this running?  |
| lazygit    | Git TUI               |
| lazydocker | Docker TUI            |
| tokei      | Code line counter     |
| miniserve  | Simple HTTP server    |
| fzf        | Fuzzy finder          |
| jq         | JSON processor        |
| uv         | Python package manager |
| direnv     | Per-directory env vars |
| sesh       | tmux session manager  |
| timg       | Terminal image viewer |
| chafa      | Terminal image viewer |
| yazi       | Terminal file manager |
| broot      | Tree-based file navigator |
| trash      | Safe `rm` → trash; Linux only (macOS ships `/usr/bin/trash`) |

## Local overrides

`~/.zshrc` and `~/.gitconfig` are not symlinks. They are real files owned by
the machine whose first lines load the repo config (`source .../zsh/zshrc`,
`[include] path = .../git/config`). Put machine-specific settings below that
line; they override the repo. Tools that append to these files
(`git config --global`, installers that edit `~/.zshrc`) never touch the repo.

## Troubleshooting

### zsh: character not in range

https://gist.github.com/jadia/1f4c2190730ef646d41823b6a6c30926

### Special characters break on tmux

https://askubuntu.com/questions/410048/utf-8-character-not-showing-properly-in-tmux


