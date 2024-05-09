#!/bin/bash
[ ! -f /opt/telekinesis/etc/config.sh ] && {
   echo "* Please put this stuff at /opt/telekinesis/ and make sure etc/config.sh exists"
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
/opt/telekinesis/ext/build-chan-sccp.sh

# build ardop modems
echo "=> ardop modems..."
/opt/telekinesis/ext/build-ardop.sh

# patch novnc so we can send passwords via url
[ ! -f /opt/telekinesis/ext/.novnc_patched ] && {
   echo "! patching noVNC to allow passing password in URL..."
   cd /opt/telekinesis/ext/noVNC
   patch -p1<../noVNC-password-in-url.patch
   touch /opt/telekinesis/ext/.novnc_patched
   cd -
}

[ ! -s /usr/share/asterisk/sounds/telekinesis ] && {
   ln -s /opt/telekinesis/voices /usr/share/asterisk/sounds/telekinesis
}

[ ! -L /usr/share/asterisk/agi-bin/telekinesis ] && {
   ln -s /opt/telekinesis/agi-bin /usr/share/asterisk/agi-bin/telekinesis
}

echo "* Fixing permissions..."
sudo chown -R ${TK_HOST_USER}:${TK_HOST_GROUP} /opt/telekinesis
sudo chown -R asterisk:${TK_HOST_GROUP} /opt/telekinesis/etc/asterisk

echo "* Adding to PATH (profile.d)"
echo "export PATH=\$PATH:/opt/telekinesis/bin" >> /etc/profile.d/telekinesis.sh

echo "* Fetching dark theme..."
/opt/telekinesis/install/tasks/fetch-dark-gtk-theme

echo "* Installing homedir files to ${TK_HOST_USER}"
/opt/telekinesis/install/tasks/install-homedir

echo "* Building voices (if needed)"
/opt/telekinesis/voices/build-all-voices.sh

echo "**** Install Done ****"
