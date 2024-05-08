#!/bin/bash

echo "Shutting down telekinesis..."
if [ -f run/nginx.pid ]; then
   echo "* Stop nginx"
   PID=$(cat run/nginx.pid)
   kill -TERM $PID
   sleep 3
   kill -KILL $PID
   rm -f run/nginx.pid
fi

if [ -f run/ari-legacy.pid ]; then
   PID=$(cat run/ari-legacy.pid)

   echo "* Stop ari-legacy (pid: ${PID})"
   kill -9 ${PID}
   rm -f run/ari-legacy.pid
fi

if [ -f run/rigctl-wrapper.pid ]; then
   PID=$(cat run/rigctl-wrapper.pid)

   echo "* Stop rigctl-wrapper (pid: ${PID})"
   kill -9 ${PID}
   rm -f run/rigctl-wrapper.pid
fi
