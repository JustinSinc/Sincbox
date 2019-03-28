#!/bin/sh
# view current list of online players
lxc exec "$1" -- /bin/su mine -c "tmux send-keys -t minecraft 'list' Enter && sleep 1 && tac /home/mine/logs/latest.log | sed -e '/players online:/q'"
