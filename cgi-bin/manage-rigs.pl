#!/usr/bin/perl
use strict;
use warnings;
use DBI;
use CGI;

print "Content-type: text/json\n\n";

my $cgi = CGI->new();
my $frm_act = $cgi->param("act");
my $frm_user = $cgi->param("user");
my $frm_pass = $cgi->param("pass");

my $db_path = "/opt/telekinesis/data/rigs.db";
my $db_sql = "/opt/telekinesis/sql/rigs.sql";
my $db_dsn = "DBI:SQLite:dbname=$db_path";
my $db_user = "";
my $db_pass = "";
my $dbh;
my $db_empty = 0;

if (! -e $db_path) {
   $db_empty = 1;
}

sub Log {
   my $data = $_[0];
}

$dbh = DBI->connect($db_dsn, $db_user, $db_pass, { RaiseError => 1 }) 
   or die "Database error: ", $DBI::errstr;

Log("* Opened database $db_path successfully\n");

# XXX: We should instead check if telekinesis_rigs table exists
if ($db_empty) {
   # Here we import the sql from ../sql/rigs.sql
   Log("* Importing $db_sql into empty $db_path\n");
   open my $fh, '<', "$db_sql" or die "Unable to open $db_sql: $!\n";

   my $db_changes = 0;
   my $sql_command = '';
   while (my $line = <$fh>) {
       chomp($line);
       $sql_command .= $line;

       if ($line =~ /;\s*$/) {
           $dbh->do($sql_command) if $sql_command =~ /\S/; # Execute the command if it's not empty
           my $stmt_changes = $dbh->rows();
           if ($stmt_changes > 0) {
              $db_changes += $dbh->rows();
           }
           $sql_command = '';
       }
   }
   close $fh;
   Log("* Import completed: $db_changes inserts\n");
} else {
   Log("* No import needed\n");
}

# Set a default, if none set
if (not defined $frm_act) {
   $frm_act = "get";
}

if ($frm_act eq "get") {
   # Query database for all rigs and emit json data
   my $sql = "SELECT * FROM telekinesis_rigs;";
   my $res = $dbh->do($sql);
   my $rows = $dbh->rows();

   if ($rows > 0) {
      print '{ "status": "OK", "action": "manage-rigs/get", "result": "payload", "payload": { "rigs": 1, "0": { "name": "ft-891", "id": 0 } } }' . "\n";
   } else {
      print '{ "status": "OK", "action": "manage-rigs/get", "result": "No rigs configured" }' . "\n";
   }
} elsif ($frm_act eq "create") {
   print '{ "status": "FAILED", "action": "manage-rigs/create", "reason": "Unsupported" }' . "\n";
} elsif ($frm_act eq "delete") {
   print '{ "status": "FAILED", "action": "manage-rigs/delete", "reason": "Unsupported" }' . "\n";
} elsif ($frm_act eq "rename") {
   print '{ "status": "FAILED", "action": "manage-rigs/rename", "reason": "Unsupported" }' . "\n";
}
