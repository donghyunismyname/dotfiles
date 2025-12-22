#!/bin/sh
# Ubuntu installation script for all CLI tools
# Automatically fetches latest versions from GitHub

set -e

# Helper function to get latest GitHub release version
get_latest_version() {
    curl -s "https://api.github.com/repos/$1/releases/latest" | sed -n 's/.*"tag_name": "v\{0,1\}\([^"]*\)".*/\1/p'
}

echo "=== Installing packages from apt ==="
sudo apt update
sudo apt install -y zsh tmux neovim bat ripgrep fd-find zoxide btop curl unzip

echo ""
echo "=== Installing eza (apt repo) ==="
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

echo ""
echo "=== Installing git-delta ==="
V=$(get_latest_version "dandavison/delta")
echo "Latest version: $V"
wget -q --show-progress "https://github.com/dandavison/delta/releases/download/${V}/git-delta_${V}_amd64.deb" -O /tmp/git-delta.deb
sudo dpkg -i /tmp/git-delta.deb
rm /tmp/git-delta.deb

echo ""
echo "=== Installing duf ==="
V=$(get_latest_version "muesli/duf")
echo "Latest version: $V"
wget -q --show-progress "https://github.com/muesli/duf/releases/download/v${V}/duf_${V}_linux_amd64.deb" -O /tmp/duf.deb
sudo dpkg -i /tmp/duf.deb
rm /tmp/duf.deb

echo ""
echo "=== Installing dust ==="
V=$(get_latest_version "bootandy/dust")
echo "Latest version: $V"
wget -q --show-progress "https://github.com/bootandy/dust/releases/download/v${V}/du-dust_${V}-1_amd64.deb" -O /tmp/dust.deb
sudo dpkg -i /tmp/dust.deb
rm /tmp/dust.deb

echo ""
echo "=== Installing procs ==="
V=$(get_latest_version "dalance/procs")
echo "Latest version: $V"
wget -q --show-progress "https://github.com/dalance/procs/releases/download/v${V}/procs-v${V}-x86_64-linux.zip" -O /tmp/procs.zip
unzip -o /tmp/procs.zip -d /tmp
sudo mv /tmp/procs /usr/local/bin/
rm /tmp/procs.zip

echo ""
echo "=== Installing lazygit ==="
V=$(get_latest_version "jesseduffield/lazygit")
echo "Latest version: $V"
wget -q --show-progress "https://github.com/jesseduffield/lazygit/releases/download/v${V}/lazygit_${V}_Linux_x86_64.tar.gz" -O /tmp/lazygit.tar.gz
tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
sudo mv /tmp/lazygit /usr/local/bin/
rm /tmp/lazygit.tar.gz

echo ""
echo "=== Installing lazydocker ==="
V=$(get_latest_version "jesseduffield/lazydocker")
echo "Latest version: $V"
wget -q --show-progress "https://github.com/jesseduffield/lazydocker/releases/download/v${V}/lazydocker_${V}_Linux_x86_64.tar.gz" -O /tmp/lazydocker.tar.gz
tar -xzf /tmp/lazydocker.tar.gz -C /tmp lazydocker
sudo mv /tmp/lazydocker /usr/local/bin/
rm /tmp/lazydocker.tar.gz

echo ""
echo "=== Installing tokei ==="
V=$(get_latest_version "XAMPPRocky/tokei")
echo "Latest version: $V"
wget -q --show-progress "https://github.com/XAMPPRocky/tokei/releases/download/v${V}/tokei-x86_64-unknown-linux-gnu.tar.gz" -O /tmp/tokei.tar.gz
tar -xzf /tmp/tokei.tar.gz -C /tmp
sudo mv /tmp/tokei /usr/local/bin/
rm /tmp/tokei.tar.gz

echo ""
echo "=== Done ==="
echo ""
echo "Installed:"
echo "  - zsh, tmux, neovim, bat, ripgrep, fd-find, zoxide, btop (apt)"
echo "  - eza (apt repo)"
echo "  - git-delta, duf, dust, procs, lazygit, lazydocker, tokei (GitHub latest)"
echo ""
echo "Add these aliases to your .zshrc or .bashrc:"
echo "  alias bat='batcat'"
echo "  alias fd='fdfind'"
