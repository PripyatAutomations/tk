#!/bin/bash

[ -z $UID ] || SUDO=sudo

cd /opt/telekinesis

echo "Shutting down telekinesis..."
if [ -f run/nginx.pid ]; then
   echo "* Stop nginx"
   PID=$(cat run/nginx.pid)
   $SUDO kill -TERM $PID
   sleep 3
   $SUDO kill -KILL $PID
   $SUDO rm -f run/nginx.pid
fi

if [ -f run/asterisk.pid ]; then
   echo "* Stop asterisk"
   ./init.d/asterisk stop
fi

if [ -f run/ari-legacy.pid ]; then
   PID=$(cat run/ari-legacy.pid)
fi

if [ ! -z "${PID}" ]; then
   echo "* Stop ari-legacy (pid: ${PID})"
   $SUDO kill -9 ${PID}
   $SUDO rm -f run/ari-legacy.pid
fi

if [ -f run/rigctl-wrapper.pid ]; then
   PID=$(cat run/rigctl-wrapper.pid)
else
   PID=$(ps aux|grep 'sbin/rigctl-wrapper'|grep -v grep | awk '{print $2}')
fi

if [ ! -z "${PID}" ]; then
   echo "* Stop rigctl-wrapper (pid: ${PID})"
   $SUDO kill -9 ${PID}
   $SUDO rm -f run/rigctl-wrapper.pid
fi

if [ -f run/fastcgi-wrapper.pid ]; then
   PID=$(cat run/fastcgi-wrapper.pid)
else
   PID=$(ps aux|grep 'sbin/fastcgi-wrapper'|grep -v grep | awk '{print $2}')
fi

if [ ! -z "${PID}" ]; then
   echo "* Stop fcgi-wrapper (pid: ${PID})"
   $SUDO kill -9 ${PID}
   $SUDO rm -f run/rigctl-wrapper.pid
fi
