#!/bin/sh

set -e

# Install zsh if not present
if ! command -v zsh >/dev/null 2>&1; then
    echo "=== Installing zsh ==="
    case "$(uname -s)" in
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y zsh
            else
                brew install zsh
            fi
            ;;
        Darwin)
            brew install zsh
            ;;
    esac
fi

# Set zsh as default shell if it isn't already
ZSH_PATH="$(command -v zsh)"
if [ -n "$ZSH_PATH" ] && [ "$SHELL" != "$ZSH_PATH" ]; then
    echo "=== Setting zsh as default shell ==="
    if ! grep -qxF "$ZSH_PATH" /etc/shells 2>/dev/null; then
        echo "Adding $ZSH_PATH to /etc/shells (requires sudo)"
        echo "$ZSH_PATH" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$ZSH_PATH"
    echo "Default shell changed to $ZSH_PATH"
fi

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

# fzf key bindings and completion (requires fzf from brew)
"$(brew --prefix)/opt/fzf/install" --all --no-update-rc

# cdhist (requires uv from brew)
uv tool install cdhist

# oh-my-zsh
if [ ! -f "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
fi

# zsh plugins (requires oh-my-zsh)
clone_or_pull https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
clone_or_pull https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-completions
