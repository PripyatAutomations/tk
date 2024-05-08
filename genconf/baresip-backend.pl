#!/usr/bin/perl
use strict;
use warnings;
use UUID::Tiny ':std';
use Sys::Hostname;
use Asterisk::AMI;
no warnings qw(Asterisk::AMI);
use File::Path qw(make_path remove_tree);

my $radio = 'radio0';
my $ua_dir = "/opt/telekinesis/run/baresip-$radio";
my $account_file = "$ua_dir/accounts";
my $config_file = "$ua_dir/config";
my $launch_file = "$ua_dir/launch.sh";
my $ast_users_file = "/opt/telekinesis/etc/asterisk/telekinesis/radio.$radio.conf";
my $ast_dialplan_file = "/opt/telekinesis/etc/asterisk/telekinesis/extensions.$radio.conf";
my $ua_user = "telekinesis-$radio";
my $ua_pass = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..16;
my $ua_host = "radio.mydomain.com";
my $ua_addr = "127.0.0.1";
my $ua_port = 5092;
my $ua_cons_port = 5555;
my $ua_http_port = 8001;
my $ua_tcp_port = 4444;
my $conf_ext = "0";
my $au_outdev = "";
my $au_indev = "";


remove_tree($ua_dir);
mkdir $ua_dir;

##############
open (our $account_fh, '>', $account_file) or die("Can't open $account_file for writing");
#my $ua_str = "<sip:" . $ua_user . '@127.0.0.1>;transport=udp;auth_pass=' . $ua_pass . ';answermode=early' . "\n";
my $ua_str = '<sip:' . $ua_user . '@' . $ua_host . ';transport=udp>;outbound="sip:' . $ua_addr . ';transport=udp";auth_pass=' . $ua_pass . ';answermode=early' . "\n";

print $account_fh <<EOF;
# SIP accounts - one account per line
#
# Displayname <sip:user\@domain;uri-params>;addr-params
#
#  uri-params:
#    ;transport={udp,tcp,tls}
#
#  addr-params:
#    ;answermode={manual,early,auto}
#    ;audio_codecs=opus/48000/2,pcma,...
#    ;audio_source=alsa,default
#    ;audio_player=alsa,default
#    ;auth_user=username
#    ;auth_pass=password
#    ;call_transfer=no
#    ;mediaenc={srtp,srtp-mand,srtp-mandf,dtls_srtp,zrtp}
#    ;medianat={stun,turn,ice}
#    ;mwi=no
#    ;outbound="sip:primary.example.com;transport=tcp"
#    ;outbound2=sip:secondary.example.com
#    ;ptime={10,20,30,40,...}
#    ;regint=3600
#    ;pubint=0 (publishing off)
#    ;regq=0.5
#    ;sipnat={outbound}
#    ;stunuser=STUN/TURN/ICE-username
#    ;stunpass=STUN/TURN/ICE-password
#    ;stunserver=stun:[user:pass]\@host[:port]
#    ;video_codecs=h264,h263,...
#
# Examples:
#
#  <sip:user\@domain.com;transport=tcp>;auth_pass=secret
#  <sip:user\@1.2.3.4;transport=tcp>;auth_pass=secret
#  <sip:user\@[2001:df8:0:16:216:6fff:fe91:614c]:5070;transport=tcp>;auth_pass=secret
#
#<sip:user\@radio.mydomain.lan>;auth_pass=PASSWORD
EOF

print $account_fh $ua_str;
close $account_fh;

open (our $config_fh, '>', $config_file) or die("Can't open $config_file for writing");
print $config_fh "# This file is auto-generated! Your changes will be clobbered by $0!\n";
print $config_fh "# Edit etc/telekinesis.yaml instead!\n";
print $config_fh <<EOF;
poll_method		epoll		# poll, select, epoll ..
sip_listen		127.0.0.1:$ua_port
call_local_timeout	20
call_max_calls		1
audio_buffer        	200     	# ms
audio_player		$au_outdev
audio_source		$au_indev
ausrc_srate		48000
auplay_srate		48000
ausrc_channels		1
auplay_channels		1
#audio_txmode		poll		# poll, thread
audio_level		no
ausrc_format		s16		# s16, float, ..
auplay_format		s16		# s16, float, ..
auenc_format		s16		# s16, float, ..
audec_format		s16		# s16, float, ..
rtp_tos			184
#rtp_ports		10000-20000
#rtp_bandwidth		512-1024 # [kbit/s]
rtcp_mux		no
jitter_buffer_delay	5-10		# frames
rtp_stats		no
#rtp_timeout		60
dns_server 1.1.1.1:53
net_interface 127.0.0.1

module_path		/usr/lib/baresip/modules
module			stdio.so
module			cons.so
module			evdev.so
module			httpd.so
module			opus.so
#module			amr.so
#module			g7221.so
module			g722.so
#module			g726.so
#module			g711.so
#module			gsm.so
#module			l16.so
#module			vumeter.so
#module			sndfile.so
#module			speex_pp.so
#module			plc.so
#module			webrtc_aec.so
module			alsa.so
module_tmp		uuid.so
module_tmp		account.so
module_app		auloop.so
module_app		contact.so
module_app		debug_cmd.so
module_app		menu.so
module_app		syslog.so

cons_listen		127.0.0.1:$ua_cons_port # cons - Console UI UDP/TCP sockets
http_listen		127.0.0.1:$ua_http_port # httpd - HTTP Server
ctrl_tcp_listen		127.0.0.1:$ua_tcp_port  # ctrl_tcp - TCP interface JSON
evdev_device		/dev/input/event0
opus_bitrate		28000 # 6000-510000
opus_stereo		no
opus_sprop_stereo	no
opus_inbandfec		no
#opus_complexity	10
opus_application	audio	# {voip,audio}
#opus_samplerate	48000
#opus_packet_loss	10	# 0-100 percent (expected packet loss)
#jack_connect_ports	yes
config
contacts
current_contact
uuid
EOF
close($config_fh);

#
open (our $launch_fh, '>', $launch_file) or die("Can't open $launch_file for writing");
print $launch_fh "#!/bin/bash\n";
print $launch_fh "# This file is auto-generated! Your changes will be clobbered by $0!\n";
print $launch_fh "# Edit etc/telekinesis.yaml instead!\n";
print $launch_fh "# Start up pipewire session, if needed:\n";
print $launch_fh "if [ $? -eq 0 ]; then\n";
print $launch_fh "	eval `cat /proc/\$P/environ | xargs -0 -n1 echo |grep -E 'DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR' | sed -e's/^/export /'`\n";
print $launch_fh "else\n";
print $launch_fh "	export DBUS_SESSION_BUS_ADDRESS=`/usr/bin/dbus-daemon --session --print-address --fork`\n";
print $launch_fh "	export XDG_RUNTIME_DIR=\$(mktemp -d /tmp/\$(id -u)-runtime-dir.XXX)\n";
print $launch_fh "	/usr/bin/pipewire </dev/null &\n";
print $launch_fh "	sleep 2;\n";
print $launch_fh "	/usr/bin/wireplumber </dev/null &\n";
print $launch_fh "	sleep 2;\n";
print $launch_fh "fi\n";
print $launch_fh "baresip -f $ua_dir/ -e \"/dial $conf_ext" . '@' . $ua_host . "\"\n";
print $launch_fh "P=\$(pgrep -f /usr/bin/pipewire -U \$USER)\n";

close $launch_fh;
chmod 0755, $launch_file;

#
open (our $ast_users_fh, '>', $ast_users_file) or die("Can't open $ast_users_file for writing");
print $ast_users_fh "; This file is auto-generated! Your changes will be clobbered by $0!\n";
print $ast_users_fh "; Edit etc/telekinesis.yaml instead!\n";
print $ast_users_fh <<EOF;
[$ua_user]
type=aor
max_contacts=1
remove_existing=yes
  
[$ua_user]
type=auth
auth_type=userpass
username=telekinesis_$radio
password=$ua_pass
 
[$ua_user]
type=endpoint
transport=transport-udp
aors=$ua_user
auth=$ua_user
dtls_auto_generate_cert=yes
webrtc=yes
context=$radio
disallow=all
allow=opus,speex,g722,ulaw,gsm
;allow=g722
;allow=g722
EOF
close $ast_users_fh;

##############
# Generate a dialplan (extensions.conf) block for this radio's bridges to be accessible
open (our $ast_dialplan_fh, '>', $ast_dialplan_file) or die("Can't open $ast_dialplan_file for writing");
print $ast_dialplan_fh "; This file is auto-generated! Your changes will be clobbered by $0!\n";
print $ast_dialplan_fh "; Edit etc/telekinesis.yaml instead!\n";
print $ast_dialplan_fh "[$radio]\n";
print $ast_dialplan_fh "exten => 0,1,NoOp()\n";
print $ast_dialplan_fh " same => n,Set(VOLUME(TX)=4)\n";
print $ast_dialplan_fh " same => n,Stasis(telekinesis,$radio);\n";
close $ast_dialplan_fh;

# Is asterisk running?
if (-e "/opt/telekinesis/var/run/asterisk/asterisk.pid") {
   # reload pjsip module in asterisk
   my $astman = Asterisk::AMI->new(PeerAddr => '127.0.0.1',
                                   PeerPort => '5038',
                                   Username => 'logout-cgi',
                                   Secret => 'tShCawPy2EY0iLtB');
   die "Unable to connect to asterisk" unless ($astman);
   $astman->send_action({ Action => 'Command', Command => 'module reload res_pjsip.so' });
   $astman->send_action({ Action => 'Command', Command => 'dialplan reload' });
}

print "Run $launch_file to start UA instance!\n";
