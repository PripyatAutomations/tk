#!/usr/bin/perl
# Here we just pass off the logout event to the cleanup script
use strict;
use warnings;
use CGI;
use DBI;
use UUID::Tiny ':std';
use Sys::Hostname;

print "Content-type: text/json\n\n";

my $cgi = CGI->new();
my $token = $cgi->param("token");
my $res_reason = "Goodbye! Come back soon!";
my $res_status = "OK";
my $res_privileges = "";

# session database
my $sess_path = "/opt/telekinesis/data/users.db";
my $sess_sql = "/opt/telekinesis/sql/user.sql";
my $ses_dsn = "DBI:SQLite:dbname=$sess_path";
my $sess_user = "";
my $sess_pass = "";
my $sess_dbh;
my $sess_db_empty = 0;
my $sess_token = "none";

my $s = "/opt/telekinesis/sbin/cleanup-users.pl";

# Pass the callsign to allow script to delete it
exec($s, $token);

sub print_status {
   # emit the data to the user
   print "{ " .
         '  "status": "' . $res_status . '", ' .
         '  "host":   "' . hostname() . '", '. 
         '  "reason": "' . $res_reason . '", ' .
         '  "token": "' . $sess_token . '", ' .
         "}\n";
}
