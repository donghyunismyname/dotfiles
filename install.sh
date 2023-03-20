set -x # Show commands
#set -e # Terminate on error

DIR=$(pwd)
ln -sn $DIR/vim/vim/        ~/.vim
ln -sn $DIR/vim/vimrc       ~/.vimrc

ln -sn $DIR/tmux/tmux.conf  ~/.tmux.conf
