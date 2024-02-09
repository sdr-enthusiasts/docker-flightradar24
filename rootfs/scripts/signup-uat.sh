#!/command/with-contenv bash
# shellcheck shell=bash disable=SC2028

apt update -qq >/dev/null 2>&1
apt install -y --no-install-recommends expect tcpdump gnupg binutils jq

gpg \
    --no-default-keyring \
    --keyring /usr/share/keyrings/flightradar24.gpg \
    --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv-keys C969F07840C430F5

touch /run/.pause-fr24feed
pkill /usr/local/bin/fr24feed

/usr/local/bin/fr24feed --signup --uat --configfile=/tmp/config.txt
key="$(sed -n 's|fr24key=\(.*\)|\1|p' /tmp/config.txt >/dev/null)"
echo "Your FR24KEY_UAT is: $key"

echo "Please save this key as an environment variable to the fr24 service in your docker-compose.yml:"
echo "    - FR25KEY_UAT=$key"
echo "Then (re)start your fr24 container to apply the value"

rm -f /run/.pause_fr24feed
