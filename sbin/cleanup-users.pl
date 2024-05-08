#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use UUID::Tiny ':std';
use Sys::Hostname;

my $db_path = "/opt/telekinesis/data/session.db";
my $db_sql = "/opt/telekinesis/sql/session.sql";
my $db_dsn = "DBI:SQLite:dbname=$db_path";
my $db_user = "";
my $db_pass = "";
my $db_empty = 0;

# get from the yaml .housekeeping.session_timeout_act
my $expiry = 10800;

# If we're passed a AuthToken, remove it from the database
my $rm_user;
my $rm_token;

# If only passed one argument, it's a token and we should delete it without caring what callsign owns it...
if (defined $ARGV[0]) {
   $rm_token = $ARGV[0];
}

my $rm_query;

# XXX: make rmtoken query
if (defined $rm_token) {
   $rm_query = "";
}
# Then, scan the sessions.db and remove expired sessions
# XXX: make query to remove all expired sessions

my $expire_tm = time() - $expiry;
my $exp_query = "DELETE FROM tk_sessions WHERE last_active < ?;";

sub Log {
   my $data = $_[0];
}

my $dbh = DBI->connect($db_dsn, $db_user, $db_pass, { RaiseError => 1 }) 
   or die "Database error: ", $DBI::errstr;

Log("* Opened database $db_path successfully\n");

my $sth;
my $res;
my $rows;

# XXX: Run our quries
if (defined $rm_query) {
   $sth = $dbh->prepare($rm_query) or die("Can't prepare remove query");
   $res = $sth->execute() or die("Can't execute remove query");
   $rows = $sth->rows();
   if ($rows > 0) {
      print "* Session deleted\n";
   } else {
      print "* Session not found\n";
   }
}

if (defined $exp_query) {
   $sth = $dbh->prepare($exp_query) or die("Can't prepare expire query");
   $res = $sth->execute() or die("Can't execute expire query");
   $rows = $sth->rows();

#   print "* Expired $rows sessions\n";
}

# XXX: query for each config that exists in etc/asterisk/net/(users|radios).*.conf and delete if not in session db
