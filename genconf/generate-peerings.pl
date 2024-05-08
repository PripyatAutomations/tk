#!/usr/bin/perl
#
# Here we generate the various peering configurations:
#	asterisk IAX2
#	wireguard tunnels
#
# Arguments:
#	<remote callsign>-<remote ssid>	Defines the node we are connecting to

use strict;
use warnings;

my $peerdir = '/opt/telekinesis/etc/asterisk/telekinesis/peerings.d';

sub genpass {
    my ($length, $charset) = @_;
    $length //= 20;
    $charset //= 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789~!@%^&*()-=_+;:<>?,./';
    
    my $str = "";
    for (my $i = 0; $i < $length; $i++) {
        my $char = substr($charset, int(rand(length($charset))), 1);
        $str .= $char;
    }
    return $str;
}


sub generate_iax_peering {
   my ( $peername ) = @_;

   # Peering file we'll generate
   my $iax_pf = "${peerdir}/iax.${peername}.conf";

   # If a file exists, rename it to .2024-05-02.bak suffix first
   if ( -e $iax_pf ) {
      my $date = localtime->strftime('%Y-%m-%d');
      my $new_fn = "$iax_pf.${date}.bak";
      rename($iax_pf, $new_fn);
   }

   # Generate 32 random characters for password
   my $iax_secret = genpass(32);

   # Generate the iax.conf
   my $content = "
[peer_${peername}]
type=friend
host=dynamic
delayreject=yes
disallow=all
context=peer_${peername}
secret=${iax_secret}
allow=10.0.0.0/255.0.0.0
   ";
   print "New config would be saved to: $iax_pf\n";
   print "***\n";
   print "$content\n";
   print "***\n";
}

generate_iax_peering("N3RYB-1");
generate_iax_peering("KD2YCK-1");
