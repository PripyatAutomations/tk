#!/usr/bin/perl
use strict;
use warnings;
use UUID::Tiny ':std';
use Sys::Hostname;
use Asterisk::AMI;
no warnings qw(Asterisk::AMI);
use File::Path qw(make_path remove_tree);

my $radio = 'radio0';
my $ast_users_file = "/opt/telekinesis/etc/asterisk/telekinesis/radio.$radio.conf";
my $ast_dialplan_file = "/opt/telekinesis/etc/asterisk/telekinesis/extensions.$radio.conf";
my $ua_user = "telekinesis-$radio";
my $ua_pass = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..16;
my $ua_host = "radio.istabpeople.com";
my $ua_addr = "127.0.0.1";
my $ua_port = 5092;
my $ua_cons_port = 5555;
my $ua_http_port = 8001;
my $ua_tcp_port = 4444;
my $conf_ext = "0";
my $au_outdev = "";
my $au_indev = "";
#open (our $account_fh, '>', $account_file) or die("Can't open $account_file for writing");

# XXX:This needs replaced with genconf ASAP
#cat etc/nginx/nginx.conf | sed \
#	-e s^%%ports.http%%^$HTTP_PORT^g \
#	-e s^%%ports.https%%^$HTTPS_PORT^g \
#	-e s^%%tk.rootdir%%^$(pwd)^g \
#	> $(pwd)/run/nginx.conf
