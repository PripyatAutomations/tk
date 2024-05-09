#!/bin/bash
. /opt/telekinesis/lib/config.sh

[ -z $UID ] || SUDO=sudo

#if [ ! -f ./sbin/genconf ]; then
#   make -C src/genconf all
#fi

if [ -f ./run/nginx.pid ]; then
   echo "*** It seems nginx is already running with pid $(cat ./run/nginx.pid) ***"
   echo "***  If this is not the case, please run ./stop.sh to cleanup first!  ***"
   exit 1
fi

$SUDO ./build.sh

for i in boot.d/*; do
   if [ -x "$i" ]; then
      echo "Starting $i"
      $SUDO $i
   fi
done


echo "* Your node should now be reachable over the following interfaces:"
/sbin/ip addr show|egrep '(mtu|inet)'

