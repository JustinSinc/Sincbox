#!/bin/sh
# start a server

# if an incorrect number of arguments are applied, display usage info
# and then exit
if [ "$#" -eq 1 ]; then
  echo "Usage: launch.sh <container>"
  exit 1
fi

# launch the specified server
lxc exec "$1" -- /bin/sh -c "/bin/su mine -c /home/mine/start.sh"
