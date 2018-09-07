#!/usr/bin/env bash
# script to set up a cards against humanity server via docker on ubuntu 18.04.1 lts

# make sure all packages are up to date
sudo apt update
sudo apt -y upgrade

# install docker-ce prerequisites
sudo apt -y install apt-transport-https ca-certificates curl software-properties-common

# install the docker gpg key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# enable the docker repo
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

# update and install docker
sudo apt update
sudo apt -y install docker-ce

# start docker and enable it on boot
sudo systemctl enable docker
sudo systemctl start docker

# add user to docker group
sudo gpasswd -a "$(whoami)" docker
sudo newgrp docker

# start the container listening on port 8080
docker run -d -p 8080:8080 emcniece/dockeryourxyzzy:dev

# to start the container on boot,
# first run `crontab -e`, then paste the following line in:
# `@reboot docker run -d -p 8080:8080 emcniece/dockeryourxyzzy:dev`
# then save the file and reboot the host machine

# your server will now be listening on http://$host:8080
