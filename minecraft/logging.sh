#!/usr/bin/env bash
# a script for basic parsing of minecraft server logs
# for serving via http

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

        # set directory to serve logs from
        logdir=/var/www/html/logs/"$server"/

        # retrieve log files
        lxc file pull --recursive "$server"/home/mine/logs/ "$tempdir"/

        # unzip archived log files
        gunzip "$tempdir"/logs/*

        # clean up log files
        for file in "$tempdir"/logs/*; do
                # remove second instance of bracketed text; in this case, log level
                sed -i -e 's/\[[^][]*\]//2' "$file"

                # remove extraneous string " : "
                sed -i 's/\ :\ / /g' "$file"
        done

        # remove old log files
        if [ -d "$logdir" ]; then
                rm -rf "$logdir"
        fi

        # recreate log directory
        mkdir -p "$logdir"

        # move log files to log directory
        mv "$tempdir"/logs/* "$logdir"/

        # display end timestamp for log purposes
        echo "Finished at "$(date +%Y%m%d-%H:%M:%S)"."
done

# end function
} 2>&1 | tee -a "$HOME"/minecraft_logging.log >/dev/null
