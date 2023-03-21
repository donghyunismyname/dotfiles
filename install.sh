set -x # Show commands
set -e # Terminate on error

DIR=$(pwd)

ln -snf $DIR/vim/vim/        ~/.vim
ln -snf $DIR/vim/vimrc       ~/.vimrc

ln -snf $DIR/tmux/tmux.conf  ~/.tmux.conf

