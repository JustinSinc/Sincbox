#!/bin/sh
# start a server
lxc exec "$1" -- /bin/sh -c "/bin/su mine -c /home/mine/start.sh"
