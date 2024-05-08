a#!/usr/bin/perl
use strict;
use warnings;
use UUID::Tiny ':std';
use Sys::Hostname;
use Asterisk::AMI;
no warnings qw(Asterisk::AMI);
use File::Path qw(make_path remove_tree);

# XXX: These need moved to config!
my $ast_user = "asterisk";
my $fcgi_perl_group = "fcgi-perl";
my $radio = 'radio0';
my $ami_file = "/opt/telekinesis/etc/asterisk/manager.d/logout-cgi.conf";
my $ari_file = "/opt/telekinesis/etc/asterisk/telekinesis/ari.$radio.conf";
my $ari_passfile = "/opt/telekinesis/run/ari.$radio.pass";
my $ari_user = "telekinesis_$radio";
my $ari_pass = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..32;


# Sort out permissions on /opt/telekinesis/etc/asterisk/telekinesis for dynamic configs by perl cgi
system("chown $ast_user:$fcgi_perl_group /opt/telekinesis/etc/asterisk/telekinesis");
system("chmod 0770 /opt/telekinesis/etc/asterisk/telekinesis");

# Generate an ari user configuration for the backends
open (our $ari_fh, '>', $ari_file) or die("Can't open $ari_file for writing");
print $ari_fh "[$ari_user]\n";
print $ari_fh "type = user\n";
print $ari_fh "read_only = no\n";
print $ari_fh "password = $ari_pass\n";
close $ari_fh;
chmod 0700, $ari_file;

my $ami_secret = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..32;
open (our $ami_fh, '>', $ami_file) or die("Can't open $ami_file for writing");
print $ami_fh "[logout-cgi]\n";
print $ami_fh "secret = ${ami_secret}\n";
print $ami_fh "deny=0.0.0.0/0.0.0.0\n";
print $ami_fh "permit=127.0.0.1/32\n";
print $ami_fh "read = system,command,user,config,dialplan\n";
print $ami_fh "write = system,command,user,config,dialplan\n";
close $ami_fh;
chmod 0700, $ami_file;

# Save to a password file
open (our $aripass_fh, '>', $ari_passfile) or die("Can't open $ari_passfile for writing");
print $aripass_fh "$ari_user:$ari_pass\n";
close $aripass_fh;
chmod 0700, $ari_passfile;

# Is asterisk running?
if (-e "/opt/telekinesis/var/run/asterisk/asterisk.pid") {
   # reload pjsip module in asterisk
   my $astman = Asterisk::AMI->new(PeerAddr => '127.0.0.1',
                                   PeerPort => '5038',
                                   Username => 'logout-cgi',
                                   Secret => '${ami_secret}');
   die "Unable to connect to asterisk" unless ($astman);
   $astman->send_action({ Action => 'Command', Command => 'module reload res_pjsip.so' });
   $astman->send_action({ Action => 'Command', Command => 'dialplan reload' });
}
