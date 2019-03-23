#!/usr/bin/env bash
# a script for backing up minecraft servers running inside lxd containers
# assumes the server files are located in $HOME of user `mine` inside each container

# shell script best practices
set -euo pipefail

# declare array of minecraft servers
servers=(container1 container2)

# wrap the script into a function for logging purposes
{

# for each server, do the following:
for server in ${servers[@]}; do
        # display start timestamp for log purposes
        echo "Started at "$(date +%Y%m%d-%H:%M:%S)"."

        # create a tarball of the server files
        echo "Creating tarball of server "$server"..."
        lxc exec "$server" -- /bin/sh -c "/bin/tar -czf /backups/"$server"_backup_"$(date +%Y%m%d)".tar.gz -C /home/mine/ ."

        # copy the tarball to ~/backups/
        echo "Copying tarball to ~/backups..."
        lxc file pull "$server"/backups/"$server"_backup_"$(date +%Y%m%d)".tar.gz "$HOME"/backups/

        # send the tarball over to the archive server
        echo "Sending tarball to archive server..."
        scp "$HOME"/backups/"$server"_backup_"$(date +%Y%m%d)".tar.gz storage:/storage/minecraft/"$server"

        # display end timestamp for log purposes
        echo "Finished at "$(date +%Y%m%d-%H:%M:%S)"."
done

# end function
} 2>&1 | tee -a "$HOME"/minecraft_backups.log >/dev/null
