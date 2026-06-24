#!/bin/bash

if /usr/bin/fr24feed --version >/dev/null 2>&1; then
	exec /usr/bin/fr24feed --signup --configfile=/tmp/config.txt
else
	exec qemu-arm-static /usr/bin/fr24feed --signup --configfile=/tmp/config.txt
fi
