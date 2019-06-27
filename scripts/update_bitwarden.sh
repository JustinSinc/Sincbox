#!/usr/bin/env bash

# pull the latest version of the container
docker pull mprasil/bitwarden:latest

# stop the existing container
docker stop bitwarden

# remove the existing container
docker rm bitwarden

# launch bitwarden-rs
sudo docker run -d      --name bitwarden \
                        --restart always \
                        --user 1001 \
                        -e DOMAIN=https://bw.seednode.co \
                        -e WEBSOCKET_ENABLED=true \
                        -e SIGNUPS_ALLOWED=false \
                        -e INVITATIONS_ALLOWED=false \
                        -e SHOW_PASSWORD_HINT=false \
                        -e LOG_FILE=/data/bitwarden.log \
                        -e ROCKET_PORT=8080 \
                        -v /bw-data/:/data/ \
                        -p 8080:8080 \
                        -p 3012:3012 \
                        mprasil/bitwarden:latest
