#!/bin/bash
# crontab
# */10 * * * * /absolute/path/to/monitor.container.sh >/dev/null 2>&1

FILE_RUN_LOCK=/root/downloads/Monitor/run.container.lock
FILE_CONTAINERS_LIST=/root/downloads/Monitor/containers.list

if [ -f $FILE_RUN_LOCK ]
then
    echo Monitor $$: last task $(cat $FILE_RUN_LOCK) still is running
    exit 1
fi

echo $$ > $FILE_RUN_LOCK

while read line
do
    url=$(echo $line | awk '{print $1}')
    cid=$(echo $line | awk '{print $2}')
    # echo url: $url cid: $cid
    /usr/bin/curl --connect-timeout 10 --max-time 20 $url >/dev/null
    if [ $? -eq 0 ]
    then
	echo Monitor.docker $$: $url is ok
    else
	echo Monitor.docker $$: $url is down
	/usr/bin/docker ps | grep $cid
	if [ $? -eq 0 ]
	then
	    echo Monitor.docker $$: container $cid is running
	    /usr/bin/docker restart $cid
	    if [ $? -eq 0 ]
	    then
		echo Monitor.docker $$: restart container $cid success
	    else
		echo Monitor.docker $$: restart container $cid fail
	    fi
	else
	    echo Monitor.docker $$: container $cid is not running
            /usr/bin/docker start $cid
            if [ $? -eq 0 ]
	    then
                echo Monitor.docker $$: start container $cid success
            else
                echo Monitor.docker $$: start container $cid fail
            fi
	fi
    fi
done <$FILE_CONTAINERS_LIST

rm -f $FILE_RUN_LOCK
exit 0
