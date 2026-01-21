#!/bin/sh
# Unified installation script for CLI tools (macOS and Linux)

set -e

trap 'echo ""; echo "❌ Installation failed"; exit 1' ERR

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    echo "=== Installing Homebrew ==="
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for Linux
    if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -f "$HOME/.linuxbrew/bin/brew" ]; then
        eval "$("$HOME/.linuxbrew/bin/brew" shellenv)"
    fi
fi

echo ""
echo "=== Installing CLI tools ==="
brew install zsh tmux neovim bat ripgrep fd git-delta eza zoxide \
    btop dust duf procs witr lazygit lazydocker tokei miniserve \
    fzf jq uv

echo ""
echo "=== Verifying installation ==="
FAILED=""
for cmd in zsh tmux nvim bat rg fd delta eza zoxide btop dust duf procs witr lazygit lazydocker tokei miniserve fzf jq uv; do
    if ! command -v $cmd >/dev/null 2>&1; then
        FAILED="$FAILED $cmd"
    fi
done

if [ -n "$FAILED" ]; then
    echo "❌ Failed to install:$FAILED"
    exit 1
fi

echo ""
echo "=== Done ==="
echo "✅ All tools installed successfully!"
