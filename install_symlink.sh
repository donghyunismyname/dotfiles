#!/bin/sh

set -x # show commands
set -e # terminate on error

echo "[WARNING] Overwrite existing dotfiles: .vim .vimrc .tmux.conf .zshrc"

DIR=$(pwd)

# vim
ln -sni $DIR/vim/vim/        ~/.vim
ln -sni $DIR/vim/vimrc       ~/.vimrc

# neovim
mkdir -p ~/.config/nvim
ln -sni $DIR/vim/init.vim    ~/.config/nvim/init.vim

# tmux
ln -sni $DIR/tmux/tmux.conf  ~/.tmux.conf

# zsh
ln -sni $DIR/zsh/zshrc       ~/.zshrc

