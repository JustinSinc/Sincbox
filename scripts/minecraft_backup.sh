#!/usr/bin/env bash
# a script to back up complete Minecraft server setups

# shell script best practice
set -euo pipefail

# set the directory the server is stored in
server_name="minecraft_misfits"

# set the filenames to use for backups
new_filename="nightly_"$(date +%Y%m%d_%H)05.tgz""
old_filename="nightly_"$(date --date="yesterday" +%Y%m%d_%H)05.tgz""

# display backup file name
echo "Backing up server to file "$new_filename"..."

# back up server files, skipping the bulky dynmap tilesets
tar --exclude=plugins/dynmap/web/tiles -zcvf "$HOME/$new_filename" -C "$HOME/$server_name" .

# let the user know it finished
echo "Backed up server to "$filename". Exiting..."

# copy the file over to gate
scp "$HOME/$new_filename" gate:

# copy the file from gate to the fallback server
ssh gate "scp "$HOME/$new_filename" fallback:minecraft_misfits/"

# delete the file from gate
ssh gate "rm "$HOME/$new_filename""

# delete the previous day's backup
rm "$HOME/$old_filename"
