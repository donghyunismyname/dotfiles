#!/bin/sh

set -x # show commands
# set -e # terminate on error

mkdir -p ~/install/

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# cdhist
 git clone --branch 3.6 http://github.com/bulletmark/cdhist ~/install/cdhist
pip3 install -U ~/install/cdhist/.

# diff-so-fancy
git clone https://github.com/so-fancy/diff-so-fancy ~/install/diff-so-fancy
sudo ln -snf ~/install/diff-so-fancy/diff-so-fancy /usr/local/bin/diff-so-fancy

# Doom Emacs
# git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
# ~/.config/emacs/bin/doom install
# sudo ln -snf ~/.config/emacs/bin/doom /usr/local/bin/doom
