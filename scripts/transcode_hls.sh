#!/usr/bin/env bash
# creates an HLS stream from a video file

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# return the exit status of the final command before a failure
set -o pipefail

# set root directory for serving streams
basedir="/var/www/html"

# set base url of stream host
streamhost="https://watch.seednode.co"

# if the user does not specify a subdirectory, unset that variable
if [ "$#" -eq 2 ]; then
	# set input filename (full path)
	inputfile="$1"

	# set output filename (without path or extension)
	outputname="$2"

	# make sure $subdirectory is unset
	unset subdirectory

	# set streamdir equal to $basedir
	streamdir="$basedir"
# set the value of the stream subdirectory, if provided
elif [ "$#" -eq 3 ]; then
	# set input filename (full path)
	inputfile="$1"

	# set output filename (without path or extension)
	outputname="$3"

	# set subdirectory
	subdirectory="/$2"

	# set streamdir equal to $basedir/$subdirectory
	streamdir="$basedir$subdirectory"
# if an incorrect number of arguments is passed, provide usage syntax
else
	echo -e "\nUsage: convert-hls <filename> [stream directory] <stream name>\n";
	exit 1;
fi

# check if the output directory already exists
if [ -d "$streamdir/$outputname" ]; then
        echo "Output directory exists. Please manually delete \`"$streamdir/$outputname"\` and then re-run the script." | tee -a "$HOME"/hls_build.log
	exit 1
fi

# if ffmpeg doesn't exist, error out
command -v ffmpeg >/dev/null 2>&1 || { echo >&2 "ffmpeg is not installed. Aborting..." | tee -a "$HOME"/hls_build.log; exit 1; }

# wrap the script into a function for logging purposes
{

# output values of all variables to the log
echo "DEBUG \$basedir is \`$basedir\`
DEBUG \$streamhost is \`$streamhost\`
DEBUG \$streamdir is \`$streamdir\`
DEBUG \$inputfile is \`$inputfile\`
DEBUG \$outputname is \`$outputname\`
DEBUG \$subdirectory is \`$subdirectory\`
DEBUG \$streamdir is \`$streamdir\`"

# create the base directory
echo "DEBUG Creating directory $streamdir/$outputname"
sudo mkdir -p "$streamdir"/"$outputname"

# create playback page
echo "DEBUG Writing index file to \`$streamdir/$outputname/index.html\`"
cat <<EOL | sudo tee "$streamdir"/"$outputname"/index.html
<script src="https://cdn.jsdelivr.net/npm/hls.js@latest"></script>
<video id="video" controls></video>
<script>
        var video = document.getElementById('video');
        if(Hls.isSupported()) {
                var hls = new Hls();
                hls.loadSource('$streamhost$subdirectory/$outputname/$outputname.m3u8');
                hls.attachMedia(video);
                hls.on(Hls.Events.MANIFEST_PARSED,function() {
                        video.play();
                });
        }

        else if (video.canPlayType('application/vnd.apple.mpegurl')) {
                video.src = '$streamhost$subdirectory/$outputname/$outputname.m3u8';
                video.addEventListener('loadedmetadata',function() {
                        video.play();
                });
        }
</script>
EOL

# convert input file to 720p at 5Mbps bitrate, output to "$streamdir"/"$outputname"
echo "DEBUG Writing HLS segments to \`$streamdir/$outputname/*.ts\`"
echo "DEBUG Began writing playlist \`$streamdir/$outputname/$outputname.m3u8\` at $(date -Iseconds)"
sudo ffmpeg     -loglevel error \
		-hide_banner \
		-y -i "$inputfile" \
		-vf scale=w=-2:720 \
		-c:a aac \
		-ar 48000 \
		-c:v h264 \
		-profile:v main \
		-crf 18 \
		-sc_threshold 0 \
		-g 120 -keyint_min 120 \
		-hls_time 4 \
		-hls_playlist_type vod \
		-b:v 5000k -maxrate 5996k \
		-bufsize 6200k \
		-b:a 128k \
		-hls_segment_filename "$streamdir"/"$outputname"/"$outputname"_%03d.ts \
		"$streamdir"/"$outputname"/"$outputname".m3u8 &

# end function
} 2>&1 | tee -a "$HOME"/hls_build.log >/dev/null

echo "DEBUG Finished writing playlist \`$streamdir/$outputname/$outputname.m3u8\` at $(date -Iseconds)" | tee -a "$HOME"/hls_build.log >/dev/null
