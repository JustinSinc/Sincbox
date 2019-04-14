#!/usr/bin/env bash
# a script for basic parsing of minecraft server logs
# for serving via http

# shell script best practice
set -uo pipefail

# declare array of minecraft servers
servers=(server1 server2 server3)

# wrap the script into a function for logging purposes
{

# for each server, do the following:
for server in ${servers[@]}; do
	# display start timestamp for log purposes
	echo -e "\nStarted log parsing for server \`"$server"\` at "$(date +%Y%m%d-%H:%M:%S)"."

	# create temporary working directory
	tempdir="$(mktemp -d)"
	echo "Created temporary working directory \`"$tempdir"\`..."

	# set directory to serve logs from
	logdir=/var/www/html/logs/"$server"/
	echo "Outputting logs to \`"$logdir"\`..."

	# retrieve log files from container
	lxc file pull --recursive "$server"/home/mine/logs/ "$tempdir"/
	echo "Pulled log files from container \`"$server"\`..."

	# remove empty log files, as they will fail to decompress
	find "$tempdir" -size 0 -print0 | xargs -0 rm -f --
	echo "Removed any empty log files..."

	# unzip archived log files
	## this is iterated for each file because gzip exits on an unrecognizable file;
	## if a file is empty, the gzip decompression would halt at that file
	for zippedfile in "$tempdir"/logs/*.gz; do
		gunzip -f "$zippedfile"
		echo "Unzipped file \`"$zippedfile"\`..."
	done

	# clean up log files
	for file in "$tempdir"/logs/*; do
		# remove second instance of bracketed text; in this case, log level
		sed -i -e 's/\[[^][]*\]//2' "$file"

		# remove extraneous string " : "
		sed -i 's/\ :\ / /g' "$file"
	done
	echo "Stripped unnecessary text from logs..."

	# remove old log files
	if [ -d "$logdir" ]; then
		rm -rf "$logdir"
		echo "Removed existing output directory \`"$logdir"\`..."
	fi

	# recreate log directory
	mkdir -p "$logdir"
	echo "Created output directory \`"$logdir"\`..."

	# move log files to log directory
	mv "$tempdir"/logs/* "$logdir"/
	echo "Moved files to output directory \`"$logdir"\`..."

	# remove temporary working directory
	rm -rf "$tempdir"
	echo "Removed temporary working directory \`"$tempdir"\`..."

	# display end timestamp for log purposes
	echo -e "Finished log parsing for server \`"$server"\` at "$(date +%Y%m%d-%H:%M:%S)".\n"
done

# end function
} 2>&1 | tee -a "$HOME"/minecraft_logging.log >/dev/null
