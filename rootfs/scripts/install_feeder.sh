#!/bin/bash

# This is a slightly updated version of FR24's install script that is available here:
# 
#!/bin/bash

# Stop on first error
set -e

# to skip any questions from APT
export DEBIAN_FRONTEND=noninteractive

AUTO_SIGNUP=0
CHANNEL=stable
SYSTEM=raspberrypi
REPO="repo-feed.flightradar24.com"

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

apt-get update -y
apt-get install dirmngr -y

if [ ! -e "/etc/apt/keyrings" ]; then
	mkdir /etc/apt/keyrings
	chmod 0755 /etc/apt/keyrings
fi

# Import GPG key for the APT repository
# C969F07840C430F5
wget -O- https://repo-feed.flightradar24.com/flightradar24.pub | gpg --dearmor > /etc/apt/keyrings/flightradar24.gpg

# Add APT repository to the config file, removing older entries if exist
mv /etc/apt/sources.list /etc/apt/sources.list.bak
grep -v flightradar24 /etc/apt/sources.list.bak > /etc/apt/sources.list  || true
echo "deb [signed-by=/etc/apt/keyrings/flightradar24.gpg] https://${REPO} flightradar24 ${SYSTEM}-${CHANNEL}" > /etc/apt/sources.list.d/fr24feed.list

apt-get update -y
apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y fr24feed

ln -s /usr/bin/fr24feed /usr/local/bin/fr24feed








