#!/bin/sh
# attach to server console

# if an incorrect number of arguments are applied, display usage info
# and then exit
if [ "$#" -eq 1 ]; then
  echo "Usage: join.sh <container>"
  exit 1
fi

# attach to the tmux pane running the server console
lxc exec "$1" -- /bin/su mine -c "tmux attach -t minecraft"
