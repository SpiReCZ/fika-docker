#!/bin/bash
set -euo pipefail

echo "Fika server"
echo "-----------"

if [ -d "/opt/srv" ]; then
	start=$(date +%s)
	echo "Started copying files to your volume/directory.. Please wait."
	cp -r /opt/srv/* /opt/server/
	rm -r /opt/srv
	end=$(date +%s)
	
	echo "Files copied to your machine in $(($end-$start)) seconds."
	cd /opt/server
	chown $(id -u):$(id -g) ./* -Rf
  echo "-----------"
fi

echo "Configuring the server"
cd /opt && \. ./config.sh

echo "-----------"
echo "Starting the server"
echo "-----------"
cd /opt/server && ./Aki.Server.exe

echo "Exiting."
exit 0
