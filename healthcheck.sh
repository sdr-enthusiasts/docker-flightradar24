#!/usr/bin/env bash
set -e

EXITCODE=0

# Check /var/log/fr24feed.log for errors
LOG_ERROR_LAST_ENTRY=$(grep '\[e\]' /var/log/fr24feed.log | tail -1)
LOG_ERROR_LAST_ENTRY_TIMESTAMP=$(date --date="$(echo $LOG_ERROR_LAST_ENTRY | cut -d ' ' -f 1,2)" +%s.%N)
TIMESTAMP_NOW=$(date +%s.%N)
RECENT_ERRORS_IN_LOG=$(echo "($TIMESTAMP_NOW - $LOG_ERROR_LAST_ENTRY_TIMESTAMP) < 100" | bc)
if [ $RECENT_ERRORS_IN_LOG -eq 0 ]; then
    echo "No recent errors in /var/log/fr24feed.log. HEALTHY"
else
    echo "Recent errors in /var/log/fr24feed.log: '${LOG_ERROR_LAST_ENTRY}'. UNHEALTHY"
    EXITCODE=1
fi

# Check /var/log/fr24feed.log for sent data in last 5 minutes
LOG_LAST_ENTRY=$(grep '\[feed\]\[i\]sent' /var/log/fr24feed.log | tail -1)
LOG_LAST_ENTRY_TIMESTAMP=$(date --date="$(echo $LOG_LAST_ENTRY | cut -d ' ' -f 1,2)" +%s.%N)
TIMESTAMP_NOW=$(date +%s.%N)
RECENT_LINE_IN_LOG=$(echo "($TIMESTAMP_NOW - $LOG_LAST_ENTRY_TIMESTAMP) < 300" | bc)
if [ $RECENT_LINE_IN_LOG -eq 1 ]; then
    echo "Data set to fr24feed in past 5 mins. HEALTHY"
else
    echo "No data sent data to fr24feed in past 5 mins. UNHEALTHY"
    EXITCODE=1
fi

# make sure we're listening on port 30334 
netstat -an | grep LISTEN | grep 30334 > /dev/null
if [ $? -eq 0 ]; then
    echo "listening for connections on port 30334. HEALTHY"
else
    echo "not listening for connections on port 30334. UNHEALTHY"
    EXITCODE=1
fi

# make sure we're listening on port 8754 
netstat -an | grep LISTEN | grep 8754 > /dev/null
if [ $? -eq 0 ]; then
    echo "listening for connections on port 8754. HEALTHY"
else
    echo "not listening for connections on port 8754. UNHEALTHY"
    EXITCODE=1
fi

# make sure we're listening on port 30003 
netstat -an | grep LISTEN | grep 30003 > /dev/null
if [ $? -eq 0 ]; then
    echo "listening for connections on port 30003. HEALTHY"
else
    echo "not listening for connections on port 30003. UNHEALTHY"
    EXITCODE=1
fi

# death count for fr24feed
SERVICEDIR=/run/s6/services/fr24feed
SERVICENAME=$(basename "${SERVICEDIR}")
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ $SERVICE_DEATHS -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

# death count for fr24feed_log
SERVICEDIR=/run/s6/services/fr24feed_log
SERVICENAME=$(basename "${SERVICEDIR}")
SERVICE_DEATHS=$(s6-svdt "${SERVICEDIR}" | grep -v "exitcode 0" | wc -l)
if [ $SERVICE_DEATHS -ge 1 ]; then
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. UNHEALTHY"
    EXITCODE=1
else
    echo "${SERVICENAME} error deaths: $SERVICE_DEATHS. HEALTHY"
fi
s6-svdt-clear "${SERVICEDIR}"

exit $EXITCODE
