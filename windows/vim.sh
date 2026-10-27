#!/bin/sh
# Run from Git Bash. Same layout as install-configs.sh, but copies instead of
# symlinks, which need admin rights or developer mode on Windows.

DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Old layout: ~/.vim is in the default runtimepath and would load stale plugins
if [ -d ~/.vim ]; then
    rm -rf ~/.vim.bak
    mv ~/.vim ~/.vim.bak
fi

mkdir -p ~/.config
rm -rf ~/.config/vim
cp -r "$DIR/vim" ~/.config/vim
cp "$DIR/vim/vimrc" ~/.vimrc
