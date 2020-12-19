#!/bin/bash

set -x

# Get arch
# Make sure `file` (libmagic) is available
FILEBINARY=$(which file)
if [ -z "$FILEBINARY" ]; then
  echo "ERROR: 'file' (libmagic) not available, cannot detect architecture!"
  exit 1
fi
FILEOUTPUT=$("${FILEBINARY}" -L "${FILEBINARY}")

# 32-bit x86
# Example output:
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-i386.so.1, stripped
# /usr/bin/file: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=d48e1d621e9b833b5d33ede3b4673535df181fe0, stripped  
if echo "${FILEOUTPUT}" | grep "Intel 80386" > /dev/null; then
  FR24REPOPATH="linux_x86_binaries"
  FR24FEEDARCH="i386"

  # Temporary override for broken versions beyond this
  FR24FILEOVERRIDE="linux_x86_binaries/fr24feed_1.0.25-3_i386.deb"
fi

# x86-64
# Example output:
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-x86_64.so.1, stripped
# /usr/bin/file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, BuildID[sha1]=6b0b86f64e36f977d088b3e7046f70a586dd60e7, stripped
if echo "${FILEOUTPUT}" | grep "x86-64" > /dev/null; then
  FR24REPOPATH="linux_x86_64_binaries"
  FR24FEEDARCH="amd64"

  # Temporary override for broken versions beyond this
  FR24FILEOVERRIDE="linux_x86_64_binaries/fr24feed_1.0.25-3_amd64.deb"
fi

# armel
# /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=f57b617d0d6cd9d483dcf847b03614809e5cd8a9, stripped
if echo "${FILEOUTPUT}" | grep "ARM" > /dev/null; then

  # armhf
  # Example outputs:
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-armhf.so.1, stripped  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  # /usr/bin/file: ELF 32-bit LSB shared object, ARM, EABI5 version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-armhf.so.3, for GNU/Linux 3.2.0, BuildID[sha1]=921490a07eade98430e10735d69858e714113c56, stripped
  if echo "${FILEOUTPUT}" | grep "armhf" > /dev/null; then
    FR24REPOPATH="rpi_binaries"
    FR24FEEDARCH="armhf"

    # Temporary override for broken versions beyond this
    FR24FILEOVERRIDE="rpi_binaries/fr24feed_1.0.25-3_armhf.deb"

  fi

  # arm64
  # Example output:
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-musl-aarch64.so.1, stripped
  # /usr/bin/file: ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, interpreter /lib/ld-linux-aarch64.so.1, for GNU/Linux 3.7.0, BuildID[sha1]=a8d6092fd49d8ec9e367ac9d451b3f55c7ae7a78, stripped
  if echo "${FILEOUTPUT}" | grep "aarch64" > /dev/null; then
    FR24REPOPATH="rpi_binaries"
    FR24FEEDARCH="armhf"

    # Temporary override for broken versions beyond this
    FR24FILEOVERRIDE="rpi_binaries/fr24feed_1.0.25-3_armhf.deb"
    
  fi

fi

# If we don't have an architecture at this point, there's been a problem and we can't continue
if [ -z "${FR24FEEDARCH}" ]; then
  echo "ERROR: Unable to determine architecture or unsupported architecture!"
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
    if [ -z "${FR24FILEOVERRIDE+x}" ]; then
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
    if file /tmp/fr24feed.deb | grep -i XML > /dev/null; then
        if grep -i "<code>nosuchkey</code>" /tmp/fr24feed.deb > /dev/null; then
            echo "Version ${FR24FEEDVERSION} for ${ARCH} doesn't appear to exist."
            rm /tmp/fr24feed.deb
            continue
        fi
    fi

    # Get version from .deb file
    FR24FEEDVERSION=$(dpkg --info /tmp/fr24feed.deb | \
                      grep -i 'Version:' | \
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
