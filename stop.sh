#!/bin/bash

. /opt/telekinesis/lib/config.sh
set -e
[ -z "$UID" ] || SUDO=sudo

cd ${TKDIR}

echo "Shutting down telekinesis..."
if [ -f ${TKDIR}/run/nginx.pid ]; then
   echo "* Stop nginx"
   PID=$(cat ${TKDIR}/run/nginx.pid)
   $SUDO kill -TERM $PID
   sleep 3
   $SUDO kill -KILL $PID
   $SUDO rm -f ${TKDIR}/run/nginx.pid
fi

if [ -f ${TKDIR}/run/asterisk.pid ]; then
   echo "* Stop asterisk"
   ${TKDIR}/init.d/asterisk stop
fi

if [ -f ${TKDIR}/run/ari-legacy.pid ]; then
   PID=$(cat ${TKDIR}/run/ari-legacy.pid)
fi

if [ ! -z "${PID}" ]; then
   echo "* Stop ari-legacy (pid: ${PID})"
   $SUDO kill -9 ${PID}
   $SUDO rm -f ${TKDIR}/run/ari-legacy.pid
fi

if [ -f ${TKDIR}/run/rigctl-wrapper.pid ]; then
   PID=$(cat ${TKDIR}/run/rigctl-wrapper.pid)
else
   PID=$(ps aux|grep 'sbin/rigctl-wrapper'|grep -v grep | awk '{print $2}')
fi

if [ ! -z "${PID}" ]; then
   echo "* Stop rigctl-wrapper (pid: ${PID})"
   $SUDO kill -9 ${PID}
   $SUDO rm -f ${TKDIR}/run/rigctl-wrapper.pid
fi

if [ -f ${TKDIR}/run/fastcgi-wrapper.pid ]; then
   PID=$(cat ${TKDIR}/run/fastcgi-wrapper.pid)
else
   PID=$(ps aux|grep 'sbin/fastcgi-wrapper'|grep -v grep | awk '{print $2}')
fi

if [ ! -z "${PID}" ]; then
   echo "* Stop fcgi-wrapper (pid: ${PID})"
   $SUDO kill -9 ${PID}
   $SUDO rm -f ${TKDIR}/run/rigctl-wrapper.pid
fi
