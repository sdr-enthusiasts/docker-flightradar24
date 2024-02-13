#!/command/with-contenv bash
# shellcheck shell=bash
set -e

EXITCODE=0

# Check traffic over the last 5 minutes
# Note - we are only checking ADSB traffic as there are generally messages even during low-traffic times
#        UAT traffic is a lot more scarse and we won't check it to avoid false UNHEALTHY reports.
TRAFFIC_FILE="${TRAFFIC_FILE:-/tmp/packets_rcvd}"
if [[ -f "${TRAFFIC_FILE}" ]]; then
    read -ra traffic <<< "$(tail -1 "${TRAFFIC_FILE}")"
    if (( $(date +%s) - traffic[0] > 600 )) || (( ${traffic[1]:-0} == 0 )); then
        echo "[UNHEALTHY] No data received from $BEASTHOST in the past 5 mins"
        EXITCODE=1
    elif (( traffic[1] == -1 )); then
        echo "[WARNING] - Cannot check data flow, try adding NET_ADMIN and NET_RAW capabilities to your container"
    else
        echo "[HEALTHY] ${traffic[1]} packets received from $BEASTHOST in the past 5 mins"
    fi
fi


# now log checks are finished, truncate log
truncate -s 0 /var/log/fr24feed.log > /dev/null 2>&1

# make sure we're listening on port 8754
if netstat -an | grep LISTEN | grep 8754 > /dev/null; then
    echo "[HEALTHY] ADSB status website is listening for connections on port 8754"
else
    echo "[UNHEALTHY] ADSB status website is not listening for connections on port 8754"
    EXITCODE=1
fi

# make sure we're listening on port 8755 if UAT is enabled
if [[ -n "$FR24KEY_UAT" ]]; then
    if netstat -an | grep LISTEN | grep 8755 > /dev/null; then
        echo "[HEALTHY] UAT status website is listening for connections on port 8755"
    else
        echo "[UNHEALTHY] UAT status website is not listening for connections on port 8755"
        EXITCODE=1
    fi
fi

# death count for fr24feed
SERVICEDIR=/run/service/fr24feed
SERVICENAME=$(basename "${SERVICEDIR}")
# shellcheck disable=SC2126
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ "$SERVICE_DEATHS" -ge 1 ]; then
    echo "[UNHEALTHY] ${SERVICENAME} error deaths: $SERVICE_DEATHS"
    EXITCODE=1
else
    echo "[HEALTHY] ${SERVICENAME} error deaths: $SERVICE_DEATHS"
fi
s6-svdt-clear "${SERVICEDIR}"

# death count for fr24uat_feed
if [[ -n "$FR24KEY_UAT" ]]; then
    SERVICEDIR=/run/service/fr24uat-feed
    SERVICENAME=$(basename "${SERVICEDIR}")
    # shellcheck disable=SC2126
    SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
    if [ "$SERVICE_DEATHS" -ge 1 ]; then
        echo "[UNHEALTHY] ${SERVICENAME} error deaths: $SERVICE_DEATHS"
        EXITCODE=1
    else
        echo "[HEALTHY] ${SERVICENAME} error deaths: $SERVICE_DEATHS"
    fi
    s6-svdt-clear "${SERVICEDIR}"
fi

# the following checks are taken from /usr/local/bin/fr24feed-status for ADSB
MONITOR_FILE="/dev/shm/decoder.txt"
# feed_status
FEED_STATUS=$(grep "feed_status=" ${MONITOR_FILE} | cut -d= -f2)
if [ "$FEED_STATUS" != 'connected' ]; then
    echo "[UNHEALTHY] fr24 ADSB feed_status=${FEED_STATUS}"
    grep "feed_status_message=" ${MONITOR_FILE}
    EXITCODE=1
else
    echo "[UNHEALTHY] fr24 ADSB feed_status=${FEED_STATUS}"
fi
# rx_connected
RX_CONNECTED=$(grep "rx_connected=" ${MONITOR_FILE} | cut -d= -f2)
if [ "$RX_CONNECTED" != '1' ]; then
    echo "[UNHEALTHY] fr24 ADSB rx_connected=${RX_CONNECTED}"
    EXITCODE=1
else
    echo "[HEALTHY] fr24 ADSB rx_connected=${RX_CONNECTED} ($(grep num_messages= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2) MSGS/$(grep num_resyncs= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2) SYNC)"
fi

# the following checks are taken from /usr/local/bin/fr24feed-status for UAT
if [[ -n "$FR24KEY_UAT" ]]; then
    MONITOR_FILE="/dev/shm/uat-decoder.txt"
    # feed_status
    FEED_STATUS=$(grep "feed_status=" ${MONITOR_FILE} | cut -d= -f2)
    if [ "$FEED_STATUS" != 'connected' ]; then
        echo "[UNHEALTHY] fr24 UAT feed_status=${FEED_STATUS}"
        grep "feed_status_message=" ${MONITOR_FILE}
        EXITCODE=1
    else
        echo "[UNHEALTHY] fr24 UAT feed_status=${FEED_STATUS}"
    fi
    # rx_connected
    RX_CONNECTED=$(grep "rx_connected=" ${MONITOR_FILE} | cut -d= -f2)
    if [ "$RX_CONNECTED" != '1' ]; then
        echo "[UNHEALTHY] fr24 UAT rx_connected=${RX_CONNECTED}"
        EXITCODE=1
    else
        echo "[HEALTHY] fr24 UAT rx_connected=${RX_CONNECTED}"
    fi
fi

exit $EXITCODE
