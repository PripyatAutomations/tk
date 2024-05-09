#!/bin/bash
[ -z "$UID" ] || SUDO=sudo

cp ext/Chroma-Hash/jquery.chroma-hash.js www/js
cp ext/toastr/build/toastr.js.map www/js
cp ext/toastr/build/toastr.min.js www/js
cp ext/toastr/build/toastr.min.css www/css
$SUDO mkdir -p log/asterisk
$SUDO mkdir -p var/run/asterisk
$SUDO mkdir -p var/cron

# build modified cron (path fixes), if needed
if [ ! -f bin/cron ]; then
   if [ ! -f ext/cron/.tk-patched ]; then
      (cd ext; patch -p0 < ../patches/0100-cron-paths.diff)
   fi
   make -C ext/cron
   cp ext/cron/cron sbin
   cp ext/cron/crontab bin
fi
