# simple makefile to assist with developing and packaging this mess...
PROJECT := telekinesis
PREFIX := /opt/telekinesis
db += db/rigs.db
db += db/session.db
db += db/users.db
VOICES_REPO := https://github.com/PripyatAutomations/Telekinesis-voices.git

all: help

showconf:
	cat etc/telekinesis.yaml | yq -C 2>&1 | less -R

build:
	./build.sh

checkps:
	ps auwwwx|egrep '(perl|nginx|rigctl)'|grep -v grep || true

start: ${db} declutter
	./start.sh

deps:
	apt install -y sqlite3
# perl stuff
	apt install -y libdbi-perl libdbd-sqlite3-perl libfcgi-perl libuuid-tiny-perl libio-async-loop-epoll-perl \
	       librpc-xml-perl libdata-structure-util-perl libyaml-perl
	cpan -i 'Net::Async::WebSocket::Client'
	cpan -i 'Net::WebSocket::Server'
	cpan -i 'Asterisk::AMI'

# asterisk/voice deps
	apt install -y libedit-dev libbluetooth-dev libcap-dev libresample1-dev libspandsp-dev libspeex-dev \
		libspeexdsp-dev libsrtp2-dev libunbound-dev libjack-dev libsqliteodbc baresip libopusfile-dev

# misc (http, TLS certs, tools, etc)
	apt install -y uacme nginx-extras fcgiwrap jq yq

restart: stop start

stop:
	./stop.sh

help:
	@echo "*** make Targets for ${PROJECT} ***"
	@echo "*** Start-Stop-Restart (root probably needed) ***"
	@echo "start\t\tStart ${PROJECT}"
	@echo "stop\t\tStop ${PROJECT}"
	@echo "restart\t\tRestart ${PROJECT}"
	@echo ""
	@echo "*** Maintenance targets ***"
	@echo "clean\t\tCleanup junk"
	@echo "distclean\tCleanup for distribution"
	@echo "deps\t\tInstall dependencies (apt - root needed)"
	@echo "install\t\tInstall into ${PREFIX}"

download-voices:
	git clone https://github.com/PripyatAutomations/Telekinesis-voices.git voices

##################
# Database Tasks #
##################
#db: db-clean db-build

#db-build: ${db}
#	./boot.d/100-database.sh

#db/%.db: sql/%.sql
#	sqlite3 $@ < $<

#############
# Installer #
#############
install: install-libs install-bins install-db install-initscripts
ifeq (${PREFIX},$(shell pwd))
	@echo "* Refusing to install over source directory! *"
	@echo "Perhaps try: ${MAKE} PREFIX=/somewhere/telekinesis install"
	@exit 1
endif
	@echo "* Installing telekinesis to ${PREFIX}"

install-libs:

install-bins:

install-db:

install-initscripts:

###########
# Cleanup #
###########
clean: declutter

declutter:
	./cleanup.sh

distclean: db-clean clean

#db-clean:
#	${RM} -f ${db}

###########

world:
	@echo "all done!"
