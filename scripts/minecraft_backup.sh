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
