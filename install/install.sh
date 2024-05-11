#!/bin/bash
[ ! -f /opt/telekinesis/lib/config.sh ] && {
   echo "You need to edit ${TKDIR}/lib/config.sh first!"
   exit 1
}

. /opt/telekinesis/lib/config.sh

echo "* updating submodules..."
git submodule init
git submodule pull

echo "* Installing host packages (apt)"
# remove this temporarily XXX: Fix pipewire stuff ASAP
sudo apt purge pipewire pipewire-alsa pipewire-bin pipewire-audio-client-libraries pipewire-jack pipewire-pulse pipewire-v4l2  pipewire-doc wireplumber
# install stuff
sudo apt install espeak-ng libespeak-ng-dev libsamplerate-dev libsamplerate0 sox ffmpeg
sudo apt install libhttp-request-params-perl libio-async-loop-epoll-perl libnet-async-http-perl libjson-perl libdata-dumper-simple-perl libhamlib-perl librpc-xml-perl
sudo apt install asterisk asterisk-core-sounds-en asterisk-flite asterisk-dev asterisk-modules baresip baresip-ffmpeg 

echo "* Installing cpan bits"
sudo cpan -i Number::Spell

echo "* building needed components..."
# Build chan_sccp-b to support cisco devices better

echo "=> chan_sccp-b..."
${TKDIR}/ext/build-chan-sccp.sh

# build ardop modems
echo "=> ardop modems..."
${TKDIR}/ext/build-ardop.sh

# patch novnc so we can send passwords via url
[ ! -f ${TKDIR}/ext/.novnc_patched ] && {
   echo "! patching noVNC to allow passing password in URL..."
   cd ${TKDIR}/ext/noVNC
   patch -p1<${TKDIR}/patches/noVNC-password-in-url.patch
   touch ${TKDIR}/ext/.novnc_patched
   cd -
}

[ ! -s /usr/share/asterisk/sounds/telekinesis ] && {
   ln -s ${TKDIR}/voices /usr/share/asterisk/sounds/telekinesis
}

[ ! -L /usr/share/asterisk/agi-bin/telekinesis ] && {
   ln -s ${TKDIR}/agi-bin /usr/share/asterisk/agi-bin/telekinesis
}

echo "* Fixing permissions..."
sudo chown -R ${TK_HOST_USER}:${TK_HOST_GROUP} ${TKDIR}
sudo chown -R asterisk:${TK_HOST_GROUP} ${TKDIR}/etc/asterisk

echo "* Adding to PATH (profile.d)"
echo "export PATH=\$PATH:${TKDIR}/bin" >> /etc/profile.d/telekinesis.sh

echo "* Fetching dark theme..."
${TKDIR}/install/tasks/fetch-dark-gtk-theme

echo "* Installing homedir files to ${TK_HOST_USER}"
${TKDIR}/install/tasks/install-homedir

echo "* Building voices (if needed)"
${TKDIR}/voices/build-all-voices.sh

echo "**** Install Done ****"
