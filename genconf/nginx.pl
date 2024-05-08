#!/usr/bin/perl
use strict;
use warnings;
use UUID::Tiny ':std';
use Sys::Hostname;
use YAML::XS 'LoadFile';
use Cwd;
#use Asterisk::AMI;
#no warnings qw(Asterisk::AMI);
use File::Path qw(make_path remove_tree);

my $nginx_conf_path = 'etc/nginx/nginx.conf';
my $output_path = 'run/nginx.conf';

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

# Path to YAML configuration file
my $yaml_file = 'etc/telekinesis.yaml';

# Load YAML configuration
my $config = LoadFile($yaml_file);

# Retrieve port values
my $HTTP_PORT = $config->{ports}->{http};
my $HTTPS_PORT = $config->{ports}->{https};

# Print port values for verification
print "HTTP Port: $HTTP_PORT\n";
print "HTTPS Port: $HTTPS_PORT\n";

# Read nginx.conf file
open my $nginx_conf_fh, '<', $nginx_conf_path or die "Can't open $nginx_conf_path: $!";
my @nginx_conf_content = <$nginx_conf_fh>;
close $nginx_conf_fh;
my $pwd = getcwd();

# Define replacement values

# Perform substitutions
foreach my $line (@nginx_conf_content) {
    $line =~ s/%%ports\.http%%/$HTTP_PORT/g;
    $line =~ s/%%ports\.https%%/$HTTPS_PORT/g;
    $line =~ s/%%tk\.rootdir%%/$pwd/g;
}

# Write modified content to output file
open my $output_fh, '>', $output_path or die "Can't open $output_path for writing: $!";
print $output_fh @nginx_conf_content;
close $output_fh;
