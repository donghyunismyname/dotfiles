#!/bin/sh

echo "[WARNING] Overwrite existing files by symbolic links:"
echo "    ~/.vimrc"
echo "    ~/.vim"
echo "    ~/.tmux.conf"
echo "    ~/.zshrc"
echo "    ~/.emacs.d"
read -p "Do you want to continue? (y/N): " ans

if [[ $ans != "y" ]]; then
    echo "Abort installation"
    exit 1
fi


DIR=$(pwd)
set -x # Show commands


# vim
ln -snf $DIR/vim/vimrc           ~/.vimrc
ln -snf $DIR/vim                 ~/.vim

# nvim
ln -snf $DIR/nvim                ~/.config/nvim

# tmux
ln -snf $DIR/tmux/tmux.conf  ~/.tmux.conf

# zsh
ln -snf $DIR/zsh/zshrc       ~/.zshrc

# emacs
ln -snf $DIR/emacs           ~/.emacs.d




# spacevim easy-to-use configuration
#ln -sni $DIR/vim/init.toml      ~/.SpaceVim.d/init.toml

# spacevim vimscript custom configuration
#mkdir -p                        ~/.SpaceVim.d/autoload
#ln -sni $DIR/vim/myspacevim.vim ~/.SpaceVim.d/autoload/myspacevim.vim



