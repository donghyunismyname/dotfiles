#!/bin/sh
# macOS installation script for all CLI tools

set -e

trap 'echo ""; echo "❌ Installation failed"; exit 1' ERR

# Check if brew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "=== Installing CLI tools ==="
brew install zsh tmux neovim bat ripgrep fd git-delta eza zoxide
brew install btop dust duf procs witr lazygit lazydocker tokei

echo ""
echo "=== Verifying installation ==="
FAILED=""
for cmd in zsh tmux nvim bat rg fd delta eza zoxide btop dust duf procs witr lazygit lazydocker tokei; do
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
echo ""
echo "Installed: zsh, tmux, neovim, bat, ripgrep, fd, git-delta, eza, zoxide"
echo "           btop, dust, duf, procs, witr, lazygit, lazydocker, tokei"
