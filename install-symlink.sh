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
ln -snfF $DIR/vim/vimrc           ~/.vimrc
ln -snfF $DIR/vim                 ~/.vim

# nvim
ln -snfF $DIR/nvim                ~/.config/nvim

# tmux
ln -snfF $DIR/tmux/tmux.conf  ~/.tmux.conf

# zsh
ln -snfF $DIR/zsh/zshrc       ~/.zshrc

# emacs
ln -snfF $DIR/emacs           ~/.emacs.d




# spacevim easy-to-use configuration
#ln -sni $DIR/vim/init.toml      ~/.SpaceVim.d/init.toml

# spacevim vimscript custom configuration
#mkdir -p                        ~/.SpaceVim.d/autoload
#ln -sni $DIR/vim/myspacevim.vim ~/.SpaceVim.d/autoload/myspacevim.vim



