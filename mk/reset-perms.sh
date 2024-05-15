#!/bin/bash
. /opt/telekinesis/lib/config.sh

set -e
[ -z "$UID" ] || SUDO=sudo

$SUDO chown -R $(id -u) ${TKDIR}
