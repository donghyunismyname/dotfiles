#!/bin/sh

set -x # show commands
# set -e # terminate on error

mkdir -p ~/install/

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/install/.fzf
~/install/.fzf/install

# cdhist
uv tool install cdhist

# oh-my-zsh (need to be installed last)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Doom Emacs
# git clone --depth 1 https://github.com/doomemacs/doomemacs ~/.config/emacs
# ~/.config/emacs/bin/doom install
# sudo ln -snf ~/.config/emacs/bin/doom /usr/local/bin/doom
