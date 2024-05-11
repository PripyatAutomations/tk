#!/bin/bash
. /opt/telekinesis/lib/config.sh
set -e
get_val ".users.www_db_user"
WWW_DB_USER=$CF_VAL
get_val ".users.www_db_group"
WWW_DB_GROUP=$CF_VAL
get_val ".users.fcgi_perl_group"
FCGI_GROUP=$CF_VAL
get_val ".users.asterisk_user"
AST_USER=$CF_VAL

# Refresh the database
${TKDIR}/sbin/tk-updatedb

echo "* Creating users/groups, if needed"
getent group ${WWW_DB_GROUP} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - Group: ${WWW_DB_GROUP}"
   addgroup --system ${WWW_DB_GROUP}
fi

getent passwd ${WWW_DB_USER} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - User: ${WWW_DB_USER}"
   mkdir -p ${TKDIR}/.empty
   touch ${TKDIR}/.empty/.keepme
   adduser --system \
   	   --comment "www-databases for telekinesis" \
   	   --home ${TKDIR}/.empty --no-create-home \
   	   --ingroup ${WWW_DB_GROUP} \
   	   --shell /bin/false ${WWW_DB_USER}
fi

echo "* Fixing permissions..."
chown root:root ${TKDIR}/run ${TKDIR}/logs
chmod 1777 ${TKDIR}/run ${TKDIR}/logs
chown ${AST_USER}:fcgi-perl ${TKDIR}/db/
chmod 1775 ${TKDIR}/db/
chmod 0660 ${TKDIR}/db/*.sqlite
