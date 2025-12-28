#!/bin/sh
# Ubuntu installation script for all CLI tools
# Automatically fetches latest versions from GitHub

set -e

CURRENT_STEP=""
trap 'echo ""; echo "❌ Installation failed at: $CURRENT_STEP"; exit 1' ERR

# Helper function to get latest GitHub release version
get_latest_version() {
    curl -s "https://api.github.com/repos/$1/releases/latest" | sed -n 's/.*"tag_name": "v\{0,1\}\([^"]*\)".*/\1/p'
}

CURRENT_STEP="apt packages"
echo "=== Installing packages from apt ==="
sudo apt update
sudo apt install -y zsh tmux neovim bat ripgrep fd-find zoxide btop curl unzip

echo ""
CURRENT_STEP="eza"
echo "=== Installing eza (apt repo) ==="
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

echo ""
CURRENT_STEP="git-delta"
echo "=== Installing git-delta ==="
V=$(get_latest_version "dandavison/delta")
echo "Latest version: $V"
wget --show-progress "https://github.com/dandavison/delta/releases/download/${V}/git-delta_${V}_amd64.deb" -O /tmp/git-delta.deb
sudo dpkg -i /tmp/git-delta.deb
rm /tmp/git-delta.deb

echo ""
CURRENT_STEP="duf"
echo "=== Installing duf ==="
V=$(get_latest_version "muesli/duf")
echo "Latest version: $V"
wget --show-progress "https://github.com/muesli/duf/releases/download/v${V}/duf_${V}_linux_amd64.deb" -O /tmp/duf.deb
sudo dpkg -i /tmp/duf.deb
rm /tmp/duf.deb

echo ""
CURRENT_STEP="dust"
echo "=== Installing dust ==="
V=$(get_latest_version "bootandy/dust")
echo "Latest version: $V"
wget --show-progress "https://github.com/bootandy/dust/releases/download/v${V}/du-dust_${V}-1_amd64.deb" -O /tmp/dust.deb
sudo dpkg -i /tmp/dust.deb
rm /tmp/dust.deb

echo ""
CURRENT_STEP="procs"
echo "=== Installing procs ==="
V=$(get_latest_version "dalance/procs")
echo "Latest version: $V"
wget --show-progress "https://github.com/dalance/procs/releases/download/v${V}/procs-v${V}-x86_64-linux.zip" -O /tmp/procs.zip
unzip -o /tmp/procs.zip -d /tmp
sudo mv /tmp/procs /usr/local/bin/
rm /tmp/procs.zip

echo ""
CURRENT_STEP="lazygit"
echo "=== Installing lazygit ==="
V=$(get_latest_version "jesseduffield/lazygit")
echo "Latest version: $V"
wget --show-progress "https://github.com/jesseduffield/lazygit/releases/download/v${V}/lazygit_${V}_Linux_x86_64.tar.gz" -O /tmp/lazygit.tar.gz
tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo mv /tmp/lazygit /usr/local/bin/
rm /tmp/lazygit.tar.gz

echo ""
CURRENT_STEP="lazydocker"
echo "=== Installing lazydocker ==="
V=$(get_latest_version "jesseduffield/lazydocker")
echo "Latest version: $V"
wget --show-progress "https://github.com/jesseduffield/lazydocker/releases/download/v${V}/lazydocker_${V}_Linux_x86_64.tar.gz" -O /tmp/lazydocker.tar.gz
tar -xzf /tmp/lazydocker.tar.gz -C /tmp lazydocker
sudo mv /tmp/lazydocker /usr/local/bin/
rm /tmp/lazydocker.tar.gz

echo ""
CURRENT_STEP="witr"
echo "=== Installing witr ==="
V=$(get_latest_version "pranshuparmar/witr")
echo "Latest version: $V"
wget --show-progress "https://github.com/pranshuparmar/witr/releases/download/v${V}/witr-linux-x86_64" -O /tmp/witr
chmod +x /tmp/witr
sudo mv /tmp/witr /usr/local/bin/

echo ""
CURRENT_STEP="tokei"
echo "=== Installing tokei ==="
# Try GitHub binary first (v12.1.2 is last version with prebuilt binaries)
TOKEI_V="12.1.2"
TOKEI_URL="https://github.com/XAMPPRocky/tokei/releases/download/v${TOKEI_V}/tokei-x86_64-unknown-linux-gnu.tar.gz"
if wget --show-progress "$TOKEI_URL" -O /tmp/tokei.tar.gz 2>/dev/null; then
    echo "Installing tokei v${TOKEI_V} from GitHub..."
    tar -xzf /tmp/tokei.tar.gz -C /tmp
    sudo mv /tmp/tokei /usr/local/bin/
    rm /tmp/tokei.tar.gz
else
    echo "GitHub binary not available, installing via cargo..."
    if ! command -v cargo >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
    fi
    cargo install tokei
fi

echo ""
echo "=== Verifying installation ==="
FAILED=""
# Note: bat -> batcat, fd -> fdfind on Ubuntu
for cmd in zsh tmux nvim batcat rg fdfind zoxide btop eza delta duf dust procs witr lazygit lazydocker tokei; do
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
echo "Installed:"
echo "  - zsh, tmux, neovim, bat, ripgrep, fd-find, zoxide, btop (apt)"
echo "  - eza (apt repo)"
echo "  - git-delta, duf, dust, procs, witr, lazygit, lazydocker, tokei (GitHub latest)"
