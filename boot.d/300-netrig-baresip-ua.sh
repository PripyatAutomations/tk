#!/bin/bash
. /opt/telekinesis/lib/config.sh
get_val ".users.baresip_user"
BARESIP_USER=$CF_VAL
get_val ".users.baresip_group"
BARESIP_GROUP=$CF_VAL

RADIO=radio0

echo "* Creating users/groups, if needed"
getent group ${BARESIP_GROUP} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - Group: ${BARESIP_GROUP}"
   addgroup --system ${BARESIP_GROUP}
fi

getent passwd ${BARESIP_USER} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - User: ${BARESIP_USER}"
   adduser --system \
   	   --comment "baresip user for telekinesis" \
   	   --home /opt/telekinesis/var/run/asterisk --no-create-home \
   	   --ingroup ${BARESIP_GROUP} \
   	   --shell /bin/false ${BARESIP_USER}
   usermod -a -G audio ${BARESIP_USER}
# Do we need to allow buttton input? not really...
#   usermod -a -G input ${BARESIP_USER}
fi

# XXX: multiradio
echo "* Configuring..."
/opt/telekinesis/genconf/baresip-backend.pl ${RADIO}

echo "* Fixing permissions..."

echo "* Starting baresip ua..."
#(sudo -u ${BARESIP_USER} env -i /opt/telekinesis/run/baresip-${RADIO}/launch.sh) &
sudo -u ${BARESIP_USER} /opt/telekinesis/run/baresip-${RADIO}/launch.sh &
