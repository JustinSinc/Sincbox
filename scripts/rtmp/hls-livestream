#!/usr/bin/env bash
# generates an hls.js player for a recorded stream ingested by nginx-rtmp-module

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# return the exit status of the final command before a failure
set -o pipefail

# created files should not be world writeable
umask 002

# set root directory for serving streams
basedir="/var/www/html"

# set name of rtmp app
app="live"

# set name of rtmp stream
stream="$1"

# set subdirectory which recorded streams will be served from
subdirectory="vods"

# set date for recording directory
date="$(date +%Y%m%d%H%M%S)"

# error out if no argument is provided
if [ "$#" -ne 1 ]; then
        exit 1;
fi

# create the stream directory
mkdir -p "$basedir"/"$subdirectory"/"$stream"/"$date"/

# move the existing files over to the new stream directory
mv "$basedir"/"$app"/"$stream"/* "$basedir"/"$subdirectory"/"$stream"/"$date"/

# create playback page
cat <<EOL > "$basedir"/"$subdirectory"/"$stream"/"$date"/index.html
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<video id="video" controls></video>
<script>
        var video = document.getElementById('video');
        if(Hls.isSupported()) {
                var hls = new Hls();
                hls.loadSource('index.m3u8');
                hls.attachMedia(video);
                hls.on(Hls.Events.MANIFEST_PARSED,function() {
                        video.play();
                });
        }
        else if (video.canPlayType('application/vnd.apple.mpegurl')) {
                video.src = 'index.m3u8';
                video.addEventListener('loadedmetadata',function() {
                        video.play();
                });
        }
</script>
EOL

# remove livestream directory now that the vod is online
rmdir "$basedir"/"$app"/"$stream"
