#!/bin/bash

# Run stop script if there's pidfiles in run/
[ -f ./run/*.pid ] && ./stop.sh

echo "* Cleaning up log/lock/pid files"
find ./run/ -type f -delete
find ./log/ -type f -delete
rm -f tmp/login.log

echo "* Removing databases"
find ./db/ -type f -name \*.sqlite -delete

echo "* Cleaning up asterisk"
rm -f etc/asterisk/telekinesis/users.*.conf
rm -f etc/asterisk/telekinesis/radio.*.conf
rm -f etc/asterisk/peers.d/*.conf
mkdir -p log/asterisk
find log/asterisk -type f -delete
