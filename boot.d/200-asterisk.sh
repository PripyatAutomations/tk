#!/bin/bash
. /opt/telekinesis/lib/config.sh
get_val ".users.asterisk_user"
AST_USER=$CF_VAL
get_val ".users.asterisk_group"
AST_GROUP=$CF_VAL
get_val ".users.fcgi_perl_group"
FCGI_GROUP=$CF_VAL

echo "* Creating users/groups, if needed"
getent group ${AST_GROUP} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - Group: ${AST_GROUP}"
   addgroup --system ${AST_GROUP}
fi

getent passwd ${AST_USER} 2>&1 >/dev/null
if [ $? -ne 0 ]; then
   echo " - User: ${AST_USER}"
   adduser --system \
   	   --comment "asterisk user for telekinesis" \
   	   --home /opt/telekinesis/var/run/asterisk --no-create-home \
   	   --ingroup ${AST_GROUP} \
   	   --shell /bin/false ${AST_USER}
   usermod -a -G audio ${AST_USER}
   usermod -a -G bluetooth ${AST_USER}
   usermod -a -G dialout ${AST_USER}
fi

echo "* Configuring: asterisk..."
/opt/telekinesis/genconf/asterisk.pl

echo "* Creating directories..."
mkdir -p /opt/telekinesis/logs/asterisk/
for i in cdr-csv/ cdr-custom/ cel-custom/; do
   mkdir -p /opt/telekinesis/logs/asterisk/$i;
done

echo "* Fixing permissions..."
ast_dirs="etc/asterisk logs/asterisk var/cache/asterisk var/lib/asterisk run/asterisk var/spool/asterisk"
real_ast_dirs=""
for i in $ast_dirs; do
    real_ast_dirs="/opt/telekinesis/$i $real_ast_dirs"
done
echo "$real_ast_dirs" | xargs chown -f -R ${AST_USER}:${FCGI_GROUP}
chmod 0770 /opt/telekinesis/etc/asterisk/

echo "* Starting: asterisk..."
sudo -u ${AST_USER} env -i /opt/telekinesis/init.d/asterisk start
