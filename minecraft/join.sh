#!/bin/sh
lxc exec "$1" -- /bin/su mine -c "tmux attach -t minecraft"
