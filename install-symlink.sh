#!/bin/sh

set -x # show commands
# set -e # terminate on error

# echo "[WARNING] Overwrite existing dotfiles: .vim .vimrc .tmux.conf .zshrc"

DIR=$(pwd)

# vim
ln -sni $DIR/vim/vimrc           ~/.vimrc
ln -sni $DIR/vim                 ~/.vim

# nvim
ln -sni $DIR/nvim                ~/.config/nvim

# tmux
ln -sni $DIR/tmux/tmux.conf  ~/.tmux.conf

# zsh
ln -sni $DIR/zsh/zshrc       ~/.zshrc




# spacevim easy-to-use configuration
#ln -sni $DIR/vim/init.toml      ~/.SpaceVim.d/init.toml

# spacevim vimscript custom configuration
#mkdir -p                        ~/.SpaceVim.d/autoload
#ln -sni $DIR/vim/myspacevim.vim ~/.SpaceVim.d/autoload/myspacevim.vim



