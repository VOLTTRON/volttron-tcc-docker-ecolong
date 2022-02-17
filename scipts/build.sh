#!/bin/bash


# TODO: install Docker version 20.10.5, build 55c4c88

# install the latest dockerfile
# sudo apt-get remove docker docker-engine docker.io
sudo apt-get update
# dpkg -l containerd*
sudo apt install containerd
sudo apt install docker.io
sudo snap install docker

printf "\n***********************************************\n"
docker --version
printf "***********************************************\n\n"

# install docker-compose version 1.28.5, build c4eb3a1f

sudo curl -L https://github.com/docker/compose/releases/download/1.28.5/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

printf "\n***********************************************\n"
docker-compose --version
printf "***********************************************\n\n"
