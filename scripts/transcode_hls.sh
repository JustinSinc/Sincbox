#!/usr/bin/env bash
# creates an hls stream from a video file
# requires nginx configured with nginx-rtmp-module to receive input streams

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# return the exit status of the final command before a failure
set -o pipefail

# make sure correct arguments are passed
if [ "$#" -ne 2 ];
	then echo -e "\nUsage: convert-hls <filename> <stream name>\n";
	exit 1;
fi

# set stream hostname
stream_host="https://watch.seednode.co"

# set output file location
stream_dir="/var/www/html"

# set input filename (full path)
input_file="$1"

# set output filename (without path or extension)
output_name="$2"

# if ffmpeg doesn't exist, error out
command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg is not installed. Aborting..."; exit 1; }

# check if the output directory already exists
if [ -d "$stream_dir/$output_name" ]; then
	echo "Output directory exists. Waiting 15 seconds, then deleting and proceeding. Ctrl-C to cancel."
	sleep 15
	sudo rm -rf "$stream_dir/$output_name"
fi

# wrap the script into a function for logging purposes
{

# create the base directory
sudo mkdir "$stream_dir"/"$output_name"

# convert input file to 720p at 2Mbps bitrate with HLS chunks of 10MB apiece, output to "$stream_dir"/"$output_name"
sudo ffmpeg -i "$input_file" -vf scale=-1:720 -b:v 2M -g 60 -hls_time 2 -hls_list_size 0 -hls_segment_size 10000000 "$stream_dir"/"$output_name"/"$output_name".m3u8 &

# create playback page
cat <<EOL | sudo tee "$stream_dir"/"$output_name".html
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<video id="video" controls></video>
<script>
	var video = document.getElementById('video');
	if(Hls.isSupported()) {
	var hls = new Hls();
	hls.loadSource('$stream_host/$output_name/$output_name.m3u8');
	hls.attachMedia(video);
	hls.on(Hls.Events.MANIFEST_PARSED,function() {
		video.play();
	});
 }

	else if (video.canPlayType('application/vnd.apple.mpegurl')) {
	video.src = '$stream_host/$output_name/$output_name.m3u8';
	video.addEventListener('loadedmetadata',function() {
		video.play();
	});
	}
</script>
EOL

# end function
} 2>&1 | tee -a "$HOME"/hls_build.log >/dev/null
