#!/usr/bin/env bash

# shell script best practice
set -uo pipefail

# declare array of minecraft servers
servers=(misfits testing)

# wrap the script into a function for logging purposes
{

# for each server, do the following:
for server in ${servers[@]}; do
        # display start timestamp for log purposes
        echo "Started at "$(date +%Y%m%d-%H:%M:%S)"."

        # create temporary working directory
        tempdir="$(mktemp -d)"

        # retrieve log files
        lxc file pull --recursive "$server"/home/mine/logs/ "$tempdir"/

        # unzip archived log files
        gunzip "$tempdir"/logs/*

        # concatenate log files
        cat "$tempdir"/logs/*.log >> /var/www/html/logs/"$server".log

        # display end timestamp for log purposes
        echo "Finished at "$(date +%Y%m%d-%H:%M:%S)"."
done

# end function
} 2>&1 | tee -a "$HOME"/minecraft_logging.log >/dev/null
