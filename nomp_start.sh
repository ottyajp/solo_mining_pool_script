#!/bin/bash

case "$1" in
	start)
		monacoind
		cd /home/tea/nomp/
		node init.js > /dev/null 2>&1 &
		;;
	stop)
		monacoin-cli stop
		pid=`ps a | grep "node init.js" | awk '{ print $1 }'`
		kill -2 $pid
		;;
	*)
		echo "Usage: nomp_start.sh {start|stop}"
		exit 1
esac

exit 0