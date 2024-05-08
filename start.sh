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

# Refresh the database
./sbin/tk-updatedb

for i in boot.d/*; do
   if [ -x "$i" ]; then
      echo "Starting $i"
      $i
   fi
done

# XXX:This needs replaced with genconf ASAP
cat etc/nginx/nginx.conf | sed \
	-e s^%%ports.http%%^$HTTP_PORT^g \
	-e s^%%ports.https%%^$HTTPS_PORT^g \
	-e s^%%tk.rootdir%%^$(pwd)^g \
	> $(pwd)/run/nginx.conf

# Start Asterisk
/usr/sbin/nginx -c $(pwd)/run/nginx.conf
PID=$(cat $(pwd)/run/nginx.pid)
echo "* nginx running as pid ${PID}"

# Start rigctld websocket wrapper
./sbin/rigctl-wrapper.pl &
PID=$!
echo ${PID} > ./run/rigctl-wrapper.pid
echo "* rigctl-wrapper running as pid ${PID}"

# Legacy asterisk ARI
./ari-bin/tk-ari-legacy.pl &
PID=$!
echo ${PID} > ./run/ari-legacy.pid
echo "* ari-legacy running as pid ${PID}"
