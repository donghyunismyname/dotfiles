docker run -dt --name $2 --gpus all -v /home:/home -v $HOME/.ssh:$HOME/.ssh -e "TERM=xterm-256color" $1
