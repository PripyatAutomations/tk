#!/bin/bash
. /opt/telekinesis/lib/config.sh

[ -z "$UID" ] || SUDO=sudo

echo "* Updating external javascript"
git submodule update
cp ${TKDIR}/ext/Chroma-Hash/jquery.chroma-hash.js www/js
cp ${TKDIR}/ext/toastr/build/toastr.js.map www/js
cp ${TKDIR}/ext/toastr/build/toastr.min.js www/js
cp ${TKDIR}/ext/toastr/build/toastr.min.css www/css

echo "* Creating directories..."
$SUDO mkdir -p ${TKDIR}/log/asterisk
$SUDO mkdir -p ${TKDIR}/var/run/asterisk
$SUDO mkdir -p ${TKDIR}/var/cron

# build modified cron (path fixes), if needed
if [ ! -f ${TKDIR}/bin/cron ]; then
   echo "* Building cron..."
   if [ ! -f ${TKDIR}/ext/cron/.tk-patched ]; then
      (cd ${TKDIR}/ext; patch -p0 < ../patches/0100-cron-paths.diff)
   fi
   make -C ${TKDIR}/ext/cron
   cp ${TKDIR}/ext/cron/cron ${TKDIR}/sbin
   cp ${TKDIR}/ext/cron/crontab ${TKDIR}/bin
fi

# Build our third-party stuff
#if [ ! -f ${TKDIR}/sbin/asterisk]; then
#   cd ${TKDIR}/ext/asterisk
#   ./configure  --prefix=${TKDIR} \
#   		--sysconfig=${TKDIR}/etc/asterisk/
#fi
