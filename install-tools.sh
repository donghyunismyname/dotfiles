#!/bin/sh
# Unified installation script for CLI tools (macOS and Linux)

set -e

trap 'echo ""; echo "❌ Installation failed"; exit 1' ERR

# Try to load existing brew from known locations
for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
    if [ -x "$brew_path" ]; then
        eval "$("$brew_path" shellenv)"
        break
    fi
done

# Install Homebrew if not present
if ! command -v brew >/dev/null 2>&1; then
    echo "=== Installing Homebrew ==="
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH after install
    for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew "$HOME/.linuxbrew/bin/brew"; do
        if [ -x "$brew_path" ]; then
            eval "$("$brew_path" shellenv)"
            break
        fi
    done
fi

echo ""
# Skip brew install if Cellar is not writable (brew owned by another user)
BREW_CELLAR="$(brew --cellar)"

# trash-cli provides a `trash` command (+ trash-restore) on Linux.
# macOS already ships /usr/bin/trash, where this formula is keg-only anyway.
EXTRA_TOOLS=""
[ "$(uname -s)" = "Linux" ] && EXTRA_TOOLS="trash-cli"

if [ -w "$BREW_CELLAR" ]; then
    echo "=== Installing CLI tools ==="
    brew install tmux neovim bat ripgrep fd git-delta eza zoxide \
        btop dust duf procs witr lazygit lazydocker tokei miniserve \
        fzf jq uv direnv sesh timg chafa yazi broot $EXTRA_TOOLS
else
    echo "=== Brew Cellar not writable ($BREW_CELLAR), skipping install ==="
    echo "    Will verify existing tools only. Missing tools must be installed manually."
fi

echo ""
echo "=== Verifying installation ==="
FAILED=""
VERIFY_CMDS="tmux nvim bat rg fd delta eza zoxide btop dust duf procs witr lazygit lazydocker tokei miniserve fzf jq uv direnv sesh timg chafa yazi broot"
[ "$(uname -s)" = "Linux" ] && VERIFY_CMDS="$VERIFY_CMDS trash"
for cmd in $VERIFY_CMDS; do
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
