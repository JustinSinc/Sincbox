#!/bin/sh
# start a minecraft server in a tmux session

# spawn new GoTTY session in a tmux session named "minecraft"
tmux has-session -t minecraft || tmux new-session -d -s minecraft

# disable automatic renaming
tmux set-option -g allow-rename off

# only resize the pane if a smaller client is actively looking at it
tmux set-option -g aggressive-resize on

# start gotty on port 1338 in window 0 of session "minecraft"
tmux send -t minecraft "java -Xms1G -Xmx2G -jar /home/mine/spigot.jar --nojline" && tmux send-key Enter

# rename window 0 to "gotty" so it is clear what is running there
tmux select-window -t minecraft:0
tmux rename-window console
