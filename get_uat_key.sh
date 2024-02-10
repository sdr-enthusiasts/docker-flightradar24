#!/bin/bash

# This is a slightly updated version of FR24's install script

# the debian installer calls systemctl and udevadm. Let's make sure that doesn't fail
echo '#/bin/bash' > /bin/systemctl
echo '#/bin/bash' > /bin/udevadm
chmod a+x /bin/systemctl /bin/udevadm

if ! gpg --version >/dev/null 2>&1; then
    apt update -y
    apt install -y --no-install-recommends gnupg binutils dirmngr
fi

# to skip any questions from APT
export DEBIAN_FRONTEND=noninteractive

if [ ! -e "/etc/apt/keyrings" ]; then
	mkdir /etc/apt/keyrings
	chmod 0755 /etc/apt/keyrings
fi

# Import GPG key for the APT repository
# C969F07840C430F5
wget -qO- https://repo-feed.flightradar24.com/flightradar24.pub | gpg --dearmor > /etc/apt/keyrings/flightradar24.gpg

echo "deb [signed-by=/etc/apt/keyrings/flightradar24.gpg] https://repo-feed.flightradar24.com flightradar24 raspberrypi-stable" > /etc/apt/sources.list.d/fr24feed.list
dpkg --add-architecture armhf
apt-get update -y
apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y fr24feed:armhf

if /usr/bin/fr24feed --version >/dev/null 2>&1; then
	exec /usr/bin/fr24feed --signup --uat --configfile=/tmp/config.txt
else
	exec qemu-arm-static /usr/bin/fr24feed --signup --uat --configfile=/tmp/config.txt
fi