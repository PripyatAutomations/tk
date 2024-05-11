#!/bin/bash
. /opt/telekinesis/lib/config.sh
set -e

[ -z "$UID" ] || SUDO=sudo

#if [ ! -f ./sbin/genconf ]; then
#   make -C src/genconf all
#fi

if [ -f $TKDIR/run/nginx.pid ]; then
   echo "*** It seems nginx is already running with pid $(cat $TKDIR/run/nginx.pid) ***"
   echo "***  If this is not the case, please run $TKDIR/stop.sh to cleanup first!  ***"
   exit 1
fi

rm -f $TKDIR/run/*.pid

# Rebuild configuration
$SUDO $TKDIR/build.sh

# And start stuff...
for i in $TKDIR/boot.d/*; do
   if [ -x "$i" ]; then
      echo "Starting $(basename $i)"
      $SUDO $i
   fi
done


echo "* Your node should now be reachable over the following interfaces:"
/sbin/ip addr show|egrep '(mtu|inet)'
