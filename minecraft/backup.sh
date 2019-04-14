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
	echo -e "\nStarted backup for server \`"$server"\` at "$(date +%Y%m%d-%H:%M:%S)"."

	# create a tarball of the server files
	lxc exec "$server" -- /bin/sh -c "/bin/tar --exclude='plugins/dynmap/web' --exclude='plugins/CoreProtect/database.db' -czf /backups/"$server"_backup_"$(date +%Y%m%d)".tar.gz -C /home/mine/ ."
	echo "Created tarball of server \`"$server"\`..."

	# copy the tarball to ~/backups/
	lxc file pull "$server"/backups/"$server"_backup_"$(date +%Y%m%d)".tar.gz "$HOME"/backups/
	echo "Copied tarball to \`~/backups\`..."

	# remove the container copy of the tarball
	lxc exec "$server" -- /bin/sh -c "/bin/rm -f /backups/*"
	echo "Removed copy of tarball from inside container..."

	# send the tarball over to the archive server
	scp "$HOME"/backups/"$server"_backup_"$(date +%Y%m%d)".tar.gz storage:/storage/minecraft/"$server"
	echo "Sent tarball to archive server..."

	# display end timestamp for log purposes
	echo "Finished backup for server \`"$server"\` at "$(date +%Y%m%d-%H:%M:%S)"."
done

# end function
} 2>&1 | tee -a "$HOME"/minecraft_backups.log >/dev/null
