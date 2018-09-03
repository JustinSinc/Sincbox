#!/usr/bin/env bash
# a script to back up complete Minecraft server setups

# shell script best practice
set -euo pipefail

# the directory the server is stored in
server_name="minecraft_misfits"

# the filename to use for backups
filename="$server_name"_"$(date +%Y%m%d_%H%M).tgz"

# display backup file name
echo "Backing up server to file "$filename"..."

# back up server files
tar --exclude="$HOME/$server_name/plugins/dynmap/web/tiles" -zcvf "$HOME"/"$filename" "$HOME"/"$server_name"

# let the user know it finished
echo "Backed up server to "$filename". Exiting..."

# copy the file over to gate
scp "$HOME"/"$filename" gate:

# copy the file from gate to the fallback server
ssh gate "scp "$HOME"/"$filename" fallback:minecraft_misfits/nightly_"$(date +%Y%m%d)".tgz"

# delete the file from gate
ssh gate "rm "$HOME"/"$filename""
