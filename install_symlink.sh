#!/bin/sh

set -x # show commands
set -e # terminate on error

# echo "[WARNING] Overwrite existing dotfiles: .vim .vimrc .tmux.conf .zshrc"

DIR=$(pwd)

# vimrc
ln -sni $DIR/vim/vimrc           ~/.vimrc

# vim colorscheme
mkdir -p                         ~/.vim/colors
ln -sni $DIR/vim/jellybeans.vim  ~/.vim/colors/jellybeans.vim

# tmux
ln -sni $DIR/tmux/tmux.conf  ~/.tmux.conf

# zsh
ln -sni $DIR/zsh/zshrc       ~/.zshrc




# spacevim easy-to-use configuration
#ln -sni $DIR/vim/init.toml      ~/.SpaceVim.d/init.toml

# spacevim vimscript custom configuration
#mkdir -p                        ~/.SpaceVim.d/autoload
#ln -sni $DIR/vim/myspacevim.vim ~/.SpaceVim.d/autoload/myspacevim.vim



