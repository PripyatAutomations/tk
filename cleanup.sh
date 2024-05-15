#!/bin/bash
. /opt/telekinesis/lib/config.sh

[ -z "$UID" ] || SUDO=sudo

# Run stop script if there's pidfiles in run/
[ -f ${TKDIR}/run/nginx.pid ] && ./stop.sh

echo "* Cleaning up logs/lock/pid files"
$SUDO find ${TKDIR}/run/ -type f -delete
$SUDO find ${TKDIR}/logs/ -type f -delete
$SUDO rm -f ${TKDIR}tmp/login.log


echo "* Cleaning up asterisk"
$SUDO rm -f ${TKDIR}/etc/asterisk/telekinesis/users.*.conf
$SUDO rm -f ${TKDIR}/etc/asterisk/telekinesis/radio.*.conf
$SUDO rm -f ${TKDIR}/etc/asterisk/peers.d/*.conf
$SUDO mkdir -p ${TKDIR}/logs/asterisk
$SUDO find ${TKDIR}/logs/asterisk -type f -delete

echo "* Cleaning system..."
$SUDO find ${TKDIR}/run/ -type f -delete

if [ "$1" == "-f" ]; then
   echo "* Removing databases"
   $SUDO find ${TKDIR}/db/ -type f -name \*.sqlite -delete
   echo "* Resetting permissions for check-in"
   ./mk/reset-perms.sh
fi
