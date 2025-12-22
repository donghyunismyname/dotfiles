#!/bin/sh
# macOS installation script for all CLI tools

set -e

# Check if brew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "=== Installing CLI tools ==="
brew install zsh tmux neovim bat ripgrep fd git-delta eza zoxide
brew install btop dust duf procs lazygit lazydocker tokei

echo ""
echo "=== Done ==="
echo ""
echo "Installed: zsh, tmux, neovim, bat, ripgrep, fd, git-delta, eza, zoxide"
echo "           btop, dust, duf, procs, lazygit, lazydocker, tokei"
