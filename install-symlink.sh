#!/bin/sh

echo "[WARNING] Overwrite existing files by symbolic links:"
echo "    ~/.vimrc"
echo "    ~/.vim"
echo "    ~/.tmux.conf"
echo "    ~/.zshrc"
# echo "    ~/.emacs.d"
# echo "    ~/.config/i3/config"
read -p "Do you want to continue? (y/N): " ans

if [ $ans != "y" ]; then
    echo "Abort installation"
    exit 1
fi


DIR=$(pwd)
# set -x # Show commands


# vim
rm -ri                            ~/.vimrc
rm -ri                            ~/.vim
ln -snfF $DIR/vim/vimrc           ~/.vimrc
ln -snfF $DIR/vim                 ~/.vim

# nvim
rm -ri                            ~/.config/nvim
ln -snfF $DIR/nvim                ~/.config/nvim

# tmux
rm -ri                        ~/.tmux.conf
ln -snfF $DIR/tmux/tmux.conf  ~/.tmux.conf

# zsh
rm -ri                        ~/.zshrc
ln -snfF $DIR/zsh/zshrc       ~/.zshrc

# i3
# rm -ri                        ~/.config/i3/config
# ln -snfF $DIR/i3/config       ~/.config/i3/config

# emacs
# rm -ri                        ~/.emacs.d
# ln -snfF $DIR/emacs           ~/.emacs.d




# spacevim easy-to-use configuration
#ln -sni $DIR/vim/init.toml      ~/.SpaceVim.d/init.toml

# spacevim vimscript custom configuration
#mkdir -p                        ~/.SpaceVim.d/autoload
#ln -sni $DIR/vim/myspacevim.vim ~/.SpaceVim.d/autoload/myspacevim.vim



