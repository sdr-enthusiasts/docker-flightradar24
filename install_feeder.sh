#!/bin/bash

# This is a slightly updated version of FR24's install script
#

# If $INSTALL_X86_NATIVE == "false" then we'll install the armhf build on x86 systems - the container will run that binary in qemu-arm-static instead of natively
# This is done because for x86, the repo is stuck on a version 1.0.44 which is not compatible with the "new" UAT feeder code (which needs >=1.0.46-1)
# INSTALL_X86_FROMDEB overrides INSTALL_X86_NATIVE and will pull a hardcoded 1.0.46-1 deb binary using curl / install that one.
INSTALL_X86_NATIVE="${INSTALL_X86_NATIVE:-true}"
INSTALL_X86_FROMDEB="${INSTALL_X86_FROMDEB:-false}"

# the debian installer calls systemctl and udevadm. Let's make sure that doesn't fail if they aren't present in a container
# (Note we don't need them because we're using S6 to control system services, and the device drivers are already disabled in the host system)
if ! which systemctl >/dev/null 2>&1; then
    echo '#/bin/bash' > /bin/systemctl
    chmod +x /bin/systemctl
fi
if ! which udevadm; then
    echo '#/bin/bash' > /bin/udevadm
    chmod +x /bin/udevadm
fi

# If this is run from a base container, we check if gpg exist, and if not we need to install a few packages:
if ! gpg --version >/dev/null 2>&1 || ! curl --version  >/dev/null 2>&1; then
    apt update -y
    apt install -y --no-install-recommends gnupg binutils dirmngr curl
fi

# to skip any questions from APT
export DEBIAN_FRONTEND=noninteractive

CHANNEL="stable"
SYSTEM="raspberrypi"
REPO="repo-feed.flightradar24.com"
FEEDER="fr24feed"

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

if [ ! -e "/etc/apt/keyrings" ]; then
	# shellcheck disable=SC2174
	mkdir -p -m 0755 /etc/apt/keyrings
fi

if [[ "${INSTALL_X86_FROMDEB,,}" == "true" ]] && { [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; }; then
	curl -sSL https://repo-feed.flightradar24.com/linux_binaries/fr24feed_1.0.46-1_amd64.deb > fr24feed_1.0.46-1_amd64.deb
	dpkg -i fr24feed_1.0.46-1_amd64.deb
else
	# If $INSTALL_X86_NATIVE == "false" then we'll install the armhf build on x86 systems - the container will run that binary in qemu-arm-static instead of natively
	# This is done because for x86, the repo is stuck on a version 1.0.44 which is not compatible with the "new" UAT feeder code (which needs >=1.0.46-1)
	if [[ "${INSTALL_X86_NATIVE,,}" == "false" ]] && { [[ "$ARCH" == "x86_64" ]] || [[ "$ARCH" == "amd64" ]]; }; then
		ARCH=arm64
		SYSTEM="raspberrypi"
		dpkg --add-architecture armhf
		FEEDER="$FEEDER:armhf"
	fi
    # allow SHA1 signing (less secure)
    # required because FR24 has not update their repo and likely won't do so for quite some time
    mkdir -p /etc/crypto-policies/back-ends
    # this has to be named seqoia.config for whatever reason
    cat > /etc/crypto-policies/back-ends/sequoia.config <<EOF
[hash_algorithms]
sha1 = "always"
EOF

    cat /etc/crypto-policies/back-ends/sequoia.config

	# Import GPG key for the APT repository
	# C969F07840C430F5
	curl -sSL https://repo-feed.flightradar24.com/flightradar24.pub | gpg --dearmor > /etc/apt/keyrings/flightradar24.gpg
	# Add APT repository to the config file, removing older entries if exist
	echo "deb [signed-by=/etc/apt/keyrings/flightradar24.gpg] https://${REPO} flightradar24 ${SYSTEM}-${CHANNEL}" > /etc/apt/sources.list.d/fr24feed.list
	apt-get update -y
	apt-get install -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -y $FEEDER

fi

# # Remove the fake systemctl and udevadm again:
# # the debian installer calls systemctl and udevadm. Let's make sure that doesn't fail
rm -f /bin/systemctl
rm -f /bin/udevadm
