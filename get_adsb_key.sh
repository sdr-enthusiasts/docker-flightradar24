#!/bin/bash

mkdir -p /run/tmp

curl -sSL https://raw.githubusercontent.com/sdr-enthusiasts/docker-flightradar24/new-uat/install_feeder.sh > /run/tmp/install_feeder.sh
chmod a+x /run/tmp/install_feeder.sh
INSTALL_X86_FROMDEB=true /run/tmp/install_feeder.sh

if /usr/bin/fr24feed --version >/dev/null 2>&1; then
	exec /usr/bin/fr24feed --signup --configfile=/tmp/config.txt
else
	exec qemu-arm-static /usr/bin/fr24feed --signup --configfile=/tmp/config.txt
fi

rm -f /run/tmp/install_feeder.sh
