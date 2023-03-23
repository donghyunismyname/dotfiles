#!/bin/sh

set -x # show commands
set -e # terminate on error

echo "[WARNING] Overwrite existing dotfiles: .vim .vimrc .tmux.conf .zshrc"

DIR=$(pwd)

ln -snf $DIR/vim/vim/        ~/.vim
ln -snf $DIR/vim/vimrc       ~/.vimrc

ln -snf $DIR/tmux/tmux.conf  ~/.tmux.conf

ln -snf $DIR/zsh/zshrc       ~/.zshrc

