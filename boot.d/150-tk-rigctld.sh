#!/bin/bash
. /opt/telekinesis/lib/config.sh
set -e
get_val ".users.baresip_user"
RIGCTL_USER=$CF_VAL
get_val ".users.baresip_group"
RIGCTL_GROUP=$CF_VAL

RADIO="radio0"

echo "* Creating users/groups, if needed"
getent group ${RIGCTL_GROUP} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - Group: ${RIGCTL_GROUP}"
   addgroup --system ${RIGCTL_GROUP}
fi

getent passwd ${RIGCTL_USER} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - User: ${RIGCTL_USER}"
   adduser --system \
   	   --comment "rigctl for telekinesis" \
   	   --home ${TKDIR}/var/run/asterisk --no-create-home \
   	   --ingroup ${RIGCTL_GROUP} \
   	   --shell /bin/false ${RIGCTL_USER}
   usermod -a -G dialout ${RIGCTL_USER}
fi

echo "* Fixing permissions..."

echo "* Starting rigctld..."
sudo -u ${RIGCTL_USER} env -i ${TKDIR}/init.d/rigctld start
sudo -u ${RIGCTL_USER} env -i ${TKDIR}/init.d/rigctl-wrapper start

echo "**********"

# Start rigctld websocket wrapper
# ${TKDIR}/sbin/rigctl-wrapper.pl &
#PID=$!
#echo ${PID} > ${TKDIR}/run/rigctl-wrapper.pid
#echo "* rigctl-wrapper running as pid ${PID}"
