#!/bin/sh
# attach to server console
lxc exec "$1" -- /bin/su mine -c "tmux attach -t minecraft"
