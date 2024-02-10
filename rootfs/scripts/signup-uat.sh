#!/command/with-contenv bash
# shellcheck shell=bash disable=SC2028

echo "Please be patient while we get a suitable version of fr24feed..."

gpg \
    --no-default-keyring \
    --keyring /usr/share/keyrings/flightradar24.gpg \
    --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv-keys C969F07840C430F5

mkdir -p /tmp/fr24feed
pushd /tmp/fr24feed >/dev/null 2>&1 || exit
  if [[ "$(uname -m)" == "x86_64x" ]]; then
    echo "Getting x86 binary"
    curl -sSLO "$(curl -sSL "https://repo-feed.flightradar24.com/fr24feed_versions.json" | jq -r '.platform["linux_x86_64_deb"]["url"]["software"]')";
  elif [[ "$(uname -m)" == "aarch64" ]]; then
    echo "Getting arm64 binary"
    curl -sSLO "$(curl -sSL "https://repo-feed.flightradar24.com/fr24feed_versions.json" | jq -r '.platform["linux_arm64_deb"]["url"]["software"]')";
  else
    echo "Getting armhf binary"
    echo 'deb [arch=armhf signed-by=/usr/share/keyrings/flightradar24.gpg] http://repo.feed.flightradar24.com flightradar24 raspberrypi-stable' > /etc/apt/sources.list.d/flightradar24.list
    apt-get update && \
    apt-get download fr24feed:armhf; \
  fi
popd >/dev/null 2>&1 || exit
# extract .deb file
ar x --output=/tmp/fr24feed -- /tmp/fr24feed/*.deb && \
# extract data.tar.gz file
mkdir -p /tmp/fr24feed/extracted && \
tar xf /tmp/fr24feed/data.tar.gz -C /tmp/fr24feed/extracted
chmod a+x /tmp/fr24feed/extracted/usr/bin/fr24feed
cp -f /tmp/fr24feed/extracted/usr/bin/fr24feed /usr/bin/fr24feed

touch /run/.pause-fr24feed
pkill -f /usr/local/bin/fr24feed

/usr/bin/fr24feed --signup --uat --configfile=/tmp/config.txt
key="$(sed -n 's|fr24key=\(.*\)|\1|p' /tmp/config.txt >/dev/null)"
echo "Your FR24KEY_UAT is: $key"

echo "Please save this key as an environment variable to the fr24 service in your docker-compose.yml:"
echo "    - FR24KEY_UAT=$key"
echo "Then (re)start your fr24 container to apply the value"

rm -f /run/.pause_fr24feed
