#!/bin/bash
. /opt/telekinesis/lib/config.sh

#if [ ! -f ./sbin/genconf ]; then
#   make -C src/genconf all
#fi

if [ -f ./run/nginx.pid ]; then
   echo "*** It seems nginx is already running with pid $(cat ./run/nginx.pid) ***"
   echo "***  If this is not the case, please run ./stop.sh to cleanup first!  ***"
   exit 1
fi

mkdir -p log/asterisk

for i in boot.d/*; do
   if [ -x "$i" ]; then
      echo "Starting $i"
      $i
   fi
done
