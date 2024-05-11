#!/bin/bash
. /opt/telekinesis/lib/config.sh
set -e
get_val ".users.fcgi_perl_user"
FCGI_USER=$CF_VAL
get_val ".users.fcgi_perl_group"
FCGI_GROUP=$CF_VAL
get_val ".users.www_db_group"
WWW_DB_GROUP=$CF_VAL

echo "* Creating users/groups, if needed"
getent group ${FCGI_GROUP} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - Group: ${FCGI_GROUP}"
   addgroup --system ${FCGI_GROUP}
fi

getent passwd ${FCGI_USER} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - User: ${FCGI_USER}"
   adduser --system \
   	   --comment "fastcgi-perl user for telekinesis" \
   	   --home ${TKDIR}/var/run/asterisk --no-create-home \
   	   --ingroup ${FCGI_GROUP} \
   	   --shell /bin/false ${FCGI_USER}
   usermod -a -G ${WWW_DB_GROUP} ${FCGI_USER}
fi

echo "* Fixing permissions..."

echo "* Starting fastcgi-perl..."
#sudo -u ${FCGI_USER} env -i ${TKDIR}/init.d/fcgi-perl start
sudo -u ${FCGI_USER} ${TKDIR}/init.d/fcgi-perl start
