#!/bin/bash
. /opt/telekinesis/lib/config.sh
get_val ".users.ari_user"
ARI_USER=$CF_VAL
get_val ".users.ari_group"
ARI_GROUP=$CF_VAL
get_val ".users.fcgi_perl_user"
FCGI_GROUP=$CF_VAL

RADIO="radio0"

echo "* Creating users/groups, if needed"
getent group ${ARI_GROUP} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - Group: ${ARI_GROUP}"
   addgroup --system ${ARI_GROUP}
fi

getent passwd ${ARI_USER} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - User: ${ARI_USER}"
   adduser --system \
   	   --comment "unprivileged ARI user for telekinesis" \
   	   --home /opt/telekinesis/.empty --no-create-home \
   	   --ingroup ${ARI_GROUP} \
   	   --shell /bin/false ${ARI_USER}
fi

echo "* Fixing permissions..."
chown ${FCGI_USER}:${ARI_GROUP} /opt/telekinesis/run/ari.${RADIO}.pass
chmod 0750 /opt/telekinesis/run/ari.${RADIO}.pass

echo "* Starting rigctl ARI (Asterisk Rest Interface)..."
sudo -u ${ARI_USER} env -i /opt/telekinesis/init.d/tk-ari start &

# Legacy asterisk ARI
#./ari-bin/tk-ari-legacy.pl &
#PID=$!
#echo ${PID} > ./run/ari-legacy.pid
#echo "* ari-legacy running as pid ${PID}"
