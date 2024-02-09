#!/command/with-contenv bash
# shellcheck shell=bash disable=SC2028

/usr/local/bin/fr24feed --signup --uat --configfile=/tmp/config.txt
key="$(sed -n 's|fr24key=\(.*\)|\1|p' /tmp/config.txt >/dev/null)"
echo "Your FR24KEY_UAT is: $key"

echo "Please save this key as an environment variable to the fr24 service in your docker-compose.yml:"
echo "    - FR25KEY_UAT=$key"
echo "Then (re)start your fr24 container to apply the value"
