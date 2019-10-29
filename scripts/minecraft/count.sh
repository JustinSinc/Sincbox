#!/bin/sh
# view current list of online players

# if an incorrect number of arguments are applied, display usage info
# and then exit
if [ "$#" -eq 1 ]; then
  echo "Usage: count.sh <container>"
  exit 1
fi

# list online players in the server console, and retrieve the output from the server log 
lxc exec "$1" -- /bin/su mine -c "tmux send-keys -t minecraft 'list' Enter && sleep 1 && tac /home/mine/logs/latest.log | sed -e '/players online:/q'"
