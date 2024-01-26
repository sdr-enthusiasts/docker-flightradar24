#!/command/with-contenv bash
# shellcheck shell=bash
set -e

EXITCODE=0

# Check /var/log/fr24feed.log for errors in last 5 minutes
LOG_ERROR_LAST_ENTRY=$(grep -a '\[e\]' /var/log/fr24feed.log | tail -1)
LOG_ERROR_LAST_ENTRY_TIMESTAMP=$(date --date="$(echo "$LOG_ERROR_LAST_ENTRY" | cut -d ' ' -f 1,2)" +%s.%N)
TIMESTAMP_NOW=$(date +%s.%N)
RECENT_ERRORS_IN_LOG=$(echo "($TIMESTAMP_NOW" - "$LOG_ERROR_LAST_ENTRY_TIMESTAMP) < 300" | bc)
if [ "$RECENT_ERRORS_IN_LOG" -eq 0 ]; then
    echo "No recent errors in /var/log/fr24feed.log. HEALTHY"
else
    echo "Recent errors in /var/log/fr24feed.log: '${LOG_ERROR_LAST_ENTRY}'. UNHEALTHY"
    EXITCODE=1
fi

# Logging is broken in fr24feeder v1.0.46-1 -- disabling this check for now
# # Check /var/log/fr24feed.log for sent data in last 5 minutes
# LOG_LAST_ENTRY=$(grep -a '\[feed\]\[i\]sent' /var/log/fr24feed.log | tail -1)
# LOG_LAST_ENTRY_TIMESTAMP=$(date --date="$(echo "$LOG_LAST_ENTRY" | cut -d ' ' -f 1,2)" +%s.%N)
# TIMESTAMP_NOW=$(date +%s.%N)
# RECENT_LINE_IN_LOG=$(echo "($TIMESTAMP_NOW - $LOG_LAST_ENTRY_TIMESTAMP) < 300" | bc)
# if [ "$RECENT_LINE_IN_LOG" -eq 1 ]; then
#     echo "Data sent to fr24feed in past 5 mins. HEALTHY"
# else
#     echo "No data sent data to fr24feed in past 5 mins. UNHEALTHY"
#     EXITCODE=1
# fi

# Check traffic over the last 5 minutes
TRAFFIC_FILE="${TRAFFIC_FILE:-/tmp/packets_rcvd}"
if [[ -f "${TRAFFIC_FILE}" ]]; then
    read -ra traffic <<< "$(tail -1 "${TRAFFIC_FILE}")"
    if (( $(date %s) - traffic[0] > 600 )) || (( traffic[1] < 1 )); then
        echo "No data received from $BEASTHOST in the past 5 mins. UNHEALTHY"
        EXITCODE=1
    else
        echo "${traffic[1]} packets received from $BEASTHOST in the past 5 mins. HEALTHY"
    fi
fi


# now log checks are finished, truncate log
truncate -s 0 /var/log/fr24feed.log > /dev/null 2>&1

# make sure we're listening on port 8754
if netstat -an | grep LISTEN | grep 8754 > /dev/null; then
    echo "listening for connections on port 8754. HEALTHY"
else
    echo "not listening for connections on port 8754. UNHEALTHY"
    EXITCODE=1
fi

# death count for fr24feed
SERVICEDIR=/run/service/fr24feed
SERVICENAME=$(basename "${SERVICEDIR}")
# shellcheck disable=SC2126
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ "$SERVICE_DEATHS" -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

# death count for fr24feed_log
SERVICEDIR=/run/service/fr24feed_log
SERVICENAME=$(basename "${SERVICEDIR}")
# shellcheck disable=SC2126
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ "$SERVICE_DEATHS" -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

# the following checks are taken from /usr/local/bin/fr24feed-status
MONITOR_FILE="/dev/shm/decoder.txt"
# feed_status
FEED_STATUS=$(grep "feed_status=" ${MONITOR_FILE} | cut -d= -f2)
if [ "$FEED_STATUS" != 'connected' ]; then
    echo "fr24 feed_status=${FEED_STATUS}. UNHEALTHY"
    grep "feed_status_message=" ${MONITOR_FILE}
    EXITCODE=1
else
    echo "fr24 feed_status=${FEED_STATUS}. HEALTHY"
fi
# rx_connected
RX_CONNECTED=$(grep "rx_connected=" ${MONITOR_FILE} | cut -d= -f2)
if [ "$RX_CONNECTED" != '1' ]; then
    echo "fr24 rx_connected=${RX_CONNECTED}. UNHEALTHY"
    EXITCODE=1
else
    echo "fr24 rx_connected=${RX_CONNECTED} ($(grep num_messages= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2) MSGS/$(grep num_resyncs= ${MONITOR_FILE} 2>/dev/null | cut -d'=' -f2) SYNC). HEALTHY"
fi

exit $EXITCODE
