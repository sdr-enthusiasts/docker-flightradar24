#!/bin/bash -x

# Get arch
ARCH=$(uname -m)

# Check to make sure arch is supported by fr24feed
if [ "$ARCH" = "x86_64" ]; then
    FR24REPOPATH="linux_x86_64_binaries"
    FR24FEEDARCH="amd64"
    #FR24FILEOVERRIDE="linux_x86_64_binaries/fr24feed_1.0.25-1_amd64.deb"
elif [ "$ARCH" = "armv7l" ]; then
    FR24REPOPATH="rpi_binaries"
    FR24FEEDARCH="armhf"
elif [ "$ARCH" = "aarch64" ]; then
    dpkg --add-architecture armhf
    FR24REPOPATH="rpi_binaries"
    FR24FEEDARCH="armhf"
else
    echo "${ARCH} architecture is not supported by flightradar24 :-("
    exit 1
fi

# Download repo index and get all .deb files available
FR24DEBS=$(curl http://repo.feed.flightradar24.com | \
  xmlstarlet fo | \
  grep -oP "^\s*<[Kk]ey>([\w\/\.\-]+)<\/[Kk]ey>" | \
  cut -d ">" -f 2 | \
  cut -d "<" -f 1 | \
  grep -i ".deb" | \
  grep "${FR24REPOPATH}" | \
  sort --reverse)

for FR24DEBFILE in $FR24DEBS
do

    # Attempt .deb file download
    if [ -z ${FR24FILEOVERRIDE+x} ]; then
        echo "Attempting to download ${FR24DEBFILE}"
        curl --silent --output /tmp/fr24feed.deb "https://repo-feed.flightradar24.com/${FR24DEBFILE}"
        CURLEXITCODE="$?"
    else
        echo "Attempting to download ${FR24FILEOVERRIDE}"
        curl --silent --output /tmp/fr24feed.deb "https://repo-feed.flightradar24.com/${FR24FILEOVERRIDE}"
        CURLEXITCODE="$?"
    fi

    # Make sure curl didn't return an error
    if [ "$CURLEXITCODE" -ne "0" ]; then
        echo "Could not download ${FR24DEBFILE}"
        continue
    fi

    # Check downloaded file
    file /tmp/fr24feed.deb | grep -i XML > /dev/null
    if [ "$?" -eq "0" ]; then
        grep -i "<code>nosuchkey</code>" /tmp/fr24feed.deb > /dev/null
        if [ "$?" -eq "0" ]; then
            echo "Version ${FR24FEEDVERSION} for ${ARCH} doesn't appear to exist."
            rm /tmp/fr24feed.deb
            continue
        fi
    fi

    # Get version from .deb file
    FR24FEEDVERSION=$(dpkg --info /tmp/fr24feed.deb | \
                      grep -i Version\: | \
                      tr -s " " | \
                      cut -d ":" -f 2 | \
                      tr -d " ")

    # Break out of loop
    echo "Downloaded ${FR24FEEDVERSION} for ${ARCH} OK"
    break
done

# Log version downloaded
echo "${FR24FEEDVERSION}_${FR24FEEDARCH}" >> /VERSION

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
