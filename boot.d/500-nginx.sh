#!/bin/bash
. /opt/telekinesis/lib/config.sh
get_val ".users.www_user"
WWW_USER=$CF_VAL
get_val ".users.www_group"
WWW_GROUP=$CF_VAL

echo "* Creating users/groups, if needed"
getent group ${WWW_GROUP} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - Group: ${WWW_GROUP}"
   addgroup --system ${WWW_GROUP}
fi

getent passwd ${WWW_USER} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - User: ${WWW_USER}"
   mkdir -p /opt/telekinesis/.empty
   touch /opt/telekinesis/.empty/.keepme
   adduser --system \
   	   --comment "unprivileged www user for telekinesis" \
   	   --home /opt/telekinesis/.empty --no-create-home \
   	   --ingroup ${WWW_GROUP} \
   	   --shell /bin/false ${WWW_USER}
fi

echo "* Fixing permissions..."

echo "* Starting nginx http server..."
#sudo -u ${WWW_USER} env -i /opt/telekinesis/init.d/nginx start
env -i /opt/telekinesis/init.d/nginx start
