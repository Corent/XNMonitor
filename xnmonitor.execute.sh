#!/bin/bash
# crontab
# */10 * * * * /absolute/path/to/xnmonitor.execute.sh >/dev/null 2>&1

SERVICE_NAME=node_exporter
FILE_RUN_LOCK=/root/downloads/Monitor/run.execute.lock
# COMMAND_CHECK_SERVICE='/usr/bin/curl --connect-timeout 10 --max-time 20 localhost:9100 >/dev/null'
# COMMAND_START_SERVICE='/usr/bin/nohup /root/downloads/node_exporter-0.15.2.linux-amd64/node_exporter &'

if [ -f $FILE_RUN_LOCK ]
then
    echo Monitor $$: last task $(cat $FILE_RUN_LOCK) still is running
    exit 1
fi

echo $$ > $FILE_RUN_LOCK

# /usr/bin/curl --connect-timeout 10 --max-time 20 localhost:9090 >/dev/null
/usr/bin/curl --connect-timeout 10 --max-time 20 localhost:9100 >/dev/null
if [ $? -eq 0 ]
then
    echo Monitor $$: $SERVICE_NAME is ok
else
    echo Monitor $$: $SERVICE_NAME is down
    prc=$(netstat -anp | grep 9100 | awk '{printf $7}' | cut -d/ -f1)
    if [ $? -eq 0 ] && [[ $prc =~ '^\d+$' ]]
    then
	echo Monitor $$: process $prc is listening 9100, shut it down
	kill -9 $prc
    fi
    # /usr/bin/nohup /root/downloads/prometheus-2.0.0.linux-amd64/prometheus --config.file=/root/downloads/prometheus-2.0.0.linux-amd64/prometheus.yml &
    /usr/bin/nohup /root/downloads/node_exporter-0.15.2.linux-amd64/node_exporter &
    if [ $? -eq 0 ]
    then
        echo Monitor $$: start $SERVICE_NAME success
    else
        echo Monitor $$: start $SERVICE_NAME fail
    fi
fi

rm -f $FILE_RUN_LOCK
exit 0
