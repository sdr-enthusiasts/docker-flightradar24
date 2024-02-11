#!/bin/bash

# This is a slightly updated version of FR24's install script that is available here:
# 

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

CHANNEL=stable
SYSTEM=raspberrypi
REPO="repo-feed.flightradar24.com"
FEEDER=fr24feed

ARCH_PATH=$(which arch || true)
LSCPU_PATH=$(which lscpu || true)
ARCH=""

if [ "" != "${ARCH_PATH}" ]; then
	ARCH=$(${ARCH_PATH})
elif [ "" != "${LSCPU_PATH}" ]; then
	ARCH=$(${LSCPU_PATH} | awk '/Architecture/{print $2}')
else
	echo "Could not detect CPU architecture, neither arch or lscpu is available!"
	exit 255
fi

case "$ARCH" in
	i386|i686|x86_64|amd64|x86|x86_32)
		SYSTEM="linux"
		;;
	aarch64|armv6l|armv7l|arm64)
		SYSTEM="raspberrypi"
		;;
	*)
		echo "Unsupported architecture ($ARCH), please contact support@fr24.com"
		exit 255
		;;
esac

# temp workaround to get the latest version of fr24feed also running in x86:
case "$ARCH" in
	x86_64|amd64)
	ARCH=arm64
	SYSTEM="raspberrypi"
	dpkg --add-architecture arm64
	FEEDER="$FEEDER:arm64"
	;;
esac

# already installed in Dockerfile, no need to do it twice
# apt-get update -y
# apt-get install dirmngr -y

if [ ! -e "/etc/apt/keyrings" ]; then
	mkdir /etc/apt/keyrings
	chmod 0755 /etc/apt/keyrings
fi

# Import GPG key for the APT repository
# C969F07840C430F5
wget -O- https://repo-feed.flightradar24.com/flightradar24.pub | gpg --dearmor > /etc/apt/keyrings/flightradar24.gpg

# Add APT repository to the config file, removing older entries if exist
echo "deb [signed-by=/etc/apt/keyrings/flightradar24.gpg] https://${REPO} flightradar24 ${SYSTEM}-${CHANNEL}" > /etc/apt/sources.list.d/fr24feed.list
apt-get update -y
apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y $FEEDER

# # Remove the fake systemctl and udevadm again:
# # the debian installer calls systemctl and udevadm. Let's make sure that doesn't fail
rm -f /bin/systemctl
rm -f /bin/udevadm






