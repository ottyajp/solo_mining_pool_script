#!/bin/bash

case "$1" in
	start)
		su tea -c "monacoind"
		cd /home/tea/
		. ./.nvm/nvm.sh
		nvm use v0.10.40
		cd /home/tea/nomp/
		node init.js > /dev/null 2>&1 &
		;;
	stop)
		sudo -u tea monacoin-cli stop
		pid=`ps -aux | grep root | grep "node init.js" | awk '{ print $2 }'`
		kill -2 $pid
		;;
	*)
		echo "Usage: nomp_start.sh {start|stop}"
		exit 1
esac

exit 0