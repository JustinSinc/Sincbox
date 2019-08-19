#!/usr/bin/env bash
## script for "multiplayer" dwarf fortress via GoTTY and tmux

## to set up a Go environment, add the following lines to your ~/.bashrc, ~/.zshrc, etc
# export GOPATH=$HOME/go
# export PATH=$PATH:$GOPATH/bin

## reload your shell config (replace .bashrc with the config file for your shell of choice)
# $ source ~/.bashrc

## then download GoTTY:
# $ wget -qO- https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz | tar xvz -C $HOME/go/bin

## sample nginx config stanza can be found at
# https://github.com/Seednode/Sincbox/blob/master/scripts/watchme/nginx_watchme.conf

## install prerequisites for dwarf fortress
# $ sudo apt-get install libsdl1.2debian libsdl-image1.2 libsdl-ttf2.0-0 libopenal1 libsndfile1 libncursesw5 libgtk2.0-0 libglu1-mesa xvfb

## download and extract dwarf fortress
# $ wget -qO- http://www.bay12games.com/dwarves/df_44_12_linux.tar.bz2 | tar -xvj -C $HOME/

## make the following changes in $HOME/df_linux/data/init/init.txt
# [SOUND:NO]
# [INTRO:NO]
# [PRINT_MODE:TEXT]

# set listen port for gotty
port="1338"

# kill any existing xvfb instances
PID="$(ps -aux | grep ":1337" | grep -v grep | awk '{print $2}')"

if [ ! -z "$PID" ]; then
        kill "$PID"
fi

# spawn new GoTTY session in a tmux session named "dorf"
tmux has-session -t dorf || tmux new-session -d -s dorf

# disable automatic renaming
tmux set-option -g allow-rename off

# only resize the pane if a smaller client is actively looking at it
tmux set-option -g aggressive-resize on

# hide the status bar
tmux set-option -g status off

# start gotty on port 1338 in window 0
tmux send -t dorf "gotty -p "$port" --title-format 'Join Me!' tmux a -t dorf" && tmux send-key Enter

# rename window 0 to "gotty" so it is clear what is running there
tmux select-window -t dorf:0
tmux rename-window gotty

# create a new window to broadcast
tmux new-window -t dorf

# select the newly created window
tmux select-window -t dorf:1
tmux rename-window dorf

# start dwarf fortress
tmux send -t dorf "Xvfb :1337 -screen 0 1024x768x16 &" && tmux send-key Enter 2>&1 >/dev/null
tmux send -t dorf "DISPLAY=:1 $HOME/df_linux/df" && tmux send-key Enter

# connect to the tmux session and show off
tmux a -t dorf
