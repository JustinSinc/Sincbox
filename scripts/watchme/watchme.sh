#!/usr/bin/env bash
## script to broadcast terminal via GoTTY

## To set up a Go environment, add the following lines to your ~/.bashrc, ~/.zshrc, etc
# export GOPATH=$HOME/go
# export PATH=$PATH:$GOPATH/bin

## Reload your shell config (replace .bashrc with the config file for your shell of choice)
# $ source ~/.zshrc

## then download GoTTY:
# $ wget -qO- https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz | tar xvz -C $HOME/go/bin/

# set listen port for gotty
port="1338"

# spawn new GoTTY session in a tmux session named "watchme"
tmux has-session -t watchme || tmux new-session -d -s watchme

# disable automatic renaming
tmux set-option -g allow-rename off

# only resize the pane if a smaller client is actively looking at it
tmux set-option -g aggressive-resize on

# start gotty on port 1338 in window 0 of session "watchme"
tmux send -t watchme "gotty -p "$port" --title-format 'Watch Me!' tmux a -t watchme" && tmux send-key Enter

# rename window 0 to "gotty" so it is clear what is running there
tmux select-window -t watchme:0
tmux rename-window gotty

# create a new window to broadcast
tmux new-window -t watchme

# connect to the tmux session and show off
tmux a -t watchme
