#!/usr/bin/env bash

set -ex

# Determine fr24feed package for target platform

echo "Running on $BUILDPLATFORM, building for $TARGETPLATFORM" > /log
case "$TARGETPLATFORM" in
  "linux/amd64" )
    FR24DOWNLOAD="linux_x86_64_binaries/fr24feed_1.0.25-3_amd64.deb"
    ;;

  "linux/386" )
    FR24DOWNLOAD="linux_x86_binaries/fr24feed_1.0.25-3_i386.deb"
    ;;

  "linux/arm64" )
    FR24DOWNLOAD="rpi_binaries/fr24feed_1.0.25-3_armhf.deb"
    ;;

  "linux/arm/v7" )
    FR24DOWNLOAD="rpi_binaries/fr24feed_1.0.25-3_armhf.deb"
    ;;

  "linux/arm/v6" )
    FR24DOWNLOAD="rpi_binaries/fr24feed_1.0.25-3_armhf.deb"
    ;;

  * )
    # If we don't have an architecture at this point, there's been a problem and we can't continue
    echo "ERROR: Unable to determine architecture or unsupported architecture!"
    echo "TARGETPLATFORM=$TARGETPLATFORM"
    echo "BUILDPLATFORM=$BUILDPLATFORM"
    exit 1
    ;;

esac

# # Download repo index and get all .deb files available
# FR24DEBS=$(curl http://repo.feed.flightradar24.com | \
#   xmlstarlet fo | \
#   grep -oP "^\s*<[Kk]ey>([\w\/\.\-]+)<\/[Kk]ey>" | \
#   cut -d ">" -f 2 | \
#   cut -d "<" -f 1 | \
#   grep -i ".deb" | \
#   grep "${FR24DOWNLOAD}" | \
#   sort --reverse)

# Attempt download of fr24feed
echo "Attempting to download ${FR24DOWNLOAD}"
if curl --output /tmp/fr24feed.deb "https://repo-feed.flightradar24.com/${FR24DOWNLOAD}"; then
  echo "Download OK"
else
  echo "Download failed!"
  exit 1
fi

# Get version from .deb file
FR24FEEDVERSION=$(dpkg --info /tmp/fr24feed.deb | \
                  grep -i 'Version:' | \
                  tr -s " " | \
                  cut -d ":" -f 2 | \
                  tr -d " ")
echo "Downloaded ${FR24FEEDVERSION} for ${TARGETPLATFORM} OK"

# Deploy fr24feed.deb
cd /tmp || exit 1
ar x /tmp/fr24feed.deb
tar xzvf data.tar.gz
find /tmp -name .DS_Store -exec rm {} \;
mv -v /tmp/usr/bin/* /usr/bin/
mv -v /tmp/usr/lib/fr24 /usr/lib/
mv -v /tmp/usr/share/fr24 /usr/share/
touch /var/log/fr24feed.log
rm -v /tmp/fr24feed.deb
