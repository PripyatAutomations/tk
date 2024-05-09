#!/bin/bash
. /opt/telekinesis/lib/config.sh

[ -z $UID ] || SUDO=sudo

# Run stop script if there's pidfiles in run/
[ -f ./run/nginx.pid ] && ./stop.sh

echo "* Cleaning up logs/lock/pid files"
$SUDO find ./run/ -type f -delete
$SUDO find ./logs/ -type f -delete
$SUDO rm -f tmp/login.log

echo "* Removing databases"
$SUDO find ./db/ -type f -name \*.sqlite -delete

echo "* Cleaning up asterisk"
$SUDO rm -f etc/asterisk/telekinesis/users.*.conf
$SUDO rm -f etc/asterisk/telekinesis/radio.*.conf
$SUDO rm -f etc/asterisk/peers.d/*.conf
$SUDO mkdir -p logs/asterisk
$SUDO find logs/asterisk -type f -delete

echo "* Cleaning system..."
$SUDO find run/ -type f -delete
