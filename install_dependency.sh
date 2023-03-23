#!/bin/sh

set -x # show commands
set -e # terminate on error

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# cdhist
git clone http://github.com/bulletmark/cdhist
cd cdhist
sudo pip3 install -U .


