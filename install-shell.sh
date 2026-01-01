#!/bin/sh

set -x # show commands

# Clone if not exists, pull if exists
clone_or_pull() {
    if [ -d "$2" ]; then
        echo "Updating $2..."
        git -C "$2" pull
    else
        echo "Cloning $1..."
        git clone "$1" "$2"
    fi
}

# fzf
clone_or_pull https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# uv (Python package manager)
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# cdhist
uv tool install cdhist

# oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# zsh plugins (requires oh-my-zsh)
clone_or_pull https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
clone_or_pull https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
