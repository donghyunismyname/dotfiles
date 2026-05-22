#!/bin/sh

set -e

# Try to load existing brew from known locations
for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$brew_path" ]; then
        eval "$("$brew_path" shellenv)"
        break
    fi
done

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

# zsh plugins
ZSH_PLUGINS="${ZSH_PLUGINS:-$HOME/.zsh/plugins}"
mkdir -p "$ZSH_PLUGINS"
clone_or_pull https://github.com/zsh-users/zsh-autosuggestions "$ZSH_PLUGINS/zsh-autosuggestions"
clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGINS/zsh-syntax-highlighting"
