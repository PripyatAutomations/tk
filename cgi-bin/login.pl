#!/usr/bin/perl
#
# XXX: We need to make a session dtabase to keep track of the tokens we give out
# XXX: Change the hardcode password
use strict;
use warnings;
use DBI;
use CGI;
use UUID::Tiny ':std';
use Sys::Hostname;
use Digest::SHA qw(sha256);
use Asterisk::AMI;
no warnings qw(Asterisk::AMI);

open my $log, '>>', "/opt/telekinesis/tmp/login.log" or die "Unable to open tmp/login.log: $!\n";

print "Content-type: text/json\n\n";

#foreach my $key (sort(keys(%ENV))) {
##    if ($key =~ m/SERVER_/) {
#       print $log "$key = $ENV{$key}\n";
##    }
#}

my $cgi = CGI->new();
my $frm_callsign = $cgi->param("callsign");
my $frm_pass = $cgi->param("pass");

# If passed login details via cmdline, use them instead of the CGI args which likely aren't present...
my $num_args = $#ARGV + 1;
if ($num_args >= 1) {
   $frm_callsign = $ARGV[0];

   if ($num_args >= 2) {
      $frm_pass = $ARGV[1];
   } else {
      $frm_pass = "";
   }
}

# If password is empty, replace it with empty sha256
if ($frm_pass eq "") {
   $frm_pass = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
}

my $res_reason = "Invalid credentials";
my $res_status = "DENIED";
my $res_privileges = "";

my $my_hostname;
if (defined($ENV{"SERVER_NAME"})) {
   $my_hostname = $ENV{"SERVER_NAME"};
   print $log "using SERVER_NAME ($my_hostname) as my name\n";
} else {
   $my_hostname = hostname();
   print $log "using hostname() ($my_hostname) as my name\n";
}

if (not defined $frm_callsign) {
   print $log "no callsign :(\n";
   $frm_callsign = "";
}

if (not defined $frm_pass) {
   $frm_pass = "";
}

# users database
my $db_path = "/opt/telekinesis/data/users.db";
my $db_sql = "/opt/telekinesis/sql/users.sql";
my $db_dsn = "DBI:SQLite:dbname=$db_path";
my $db_user = "";
my $db_pass = "";
my $dbh;
my $db_empty = 0;

# session database
my $sess_path = "/opt/telekinesis/data/users.db";
my $sess_sql = "/opt/telekinesis/sql/user.sql";
my $ses_dsn = "DBI:SQLite:dbname=$sess_path";
my $sess_user = "";
my $sess_pass = "";
my $sess_dbh;
my $sess_db_empty = 0;

my $sess_token = "none";

# SIP user autocreation
my $sip_user = "";
my $sip_pass = "";
my $sip_user_compact;

sub print_status {
   # emit the data to the user
   print $log "print_status\n";
   # XXX: We should put this into a python hash and serialize it, so we can ommit empty fields...
   print "{ " .
         '  "status": "' . $res_status . '", ' .
         '  "host":   "' . $my_hostname . '", '. 
         '  "reason": "' . $res_reason . '", ' .
         '  "privileges": "' . $res_privileges . '", ' .
         '  "token": "' . $sess_token . '", ' .
         '  "callsign": "' . $frm_callsign . '", ' .
         '  "sip_user": "' . $sip_user . '", ' .
         '  "sip_pass": "' . $sip_pass . '" ' .
         "}\n";
   print $log "sending status $res_status for reason '$res_reason' to $frm_callsign ($sess_token) with sip creds '$sip_user:$sip_pass' and privileges '$res_privileges'\n";
   close $log;

   if ($res_status eq "OK") {
      exit 0;
   }
   exit 1;
}

if (not defined $frm_callsign) {
   $frm_callsign = "";
   print $log "* no callsign\n";
   $res_reason = "No callsign given";
   print_status();
}

if ($frm_callsign eq "") {
   $res_reason = "No callsign provided";
   print_status();
}

# uppercase the callsign for db query
$frm_callsign = uc($frm_callsign);

if (! -e $db_path) {
   $db_empty = 1;
}

print $log "* Opening db...\n";
$dbh = DBI->connect($db_dsn, $db_user, $db_pass, { PrintError => 1, RaiseError => 1 });
if (!$dbh) {
   print $log "db connection to $db_path failed!\n";
   die "db error";
}

print $log "* Opened database $db_path successfully\n";

# XXX: We should instead check if telekinesis_userss table exists
if ($db_empty) {
   # Here we import the sql from ../sql/users.sql
   print $log "* Importing $db_sql into empty $db_path\n";
   open my $fh, '<', "$db_sql" or die "Unable to open $db_sql: $!\n";

   my $db_changes = 0;
   my $sql_command = '';
   while (my $line = <$fh>) {
       chomp($line);
       $sql_command .= $line;

       if ($line =~ /;\s*$/) {
           $dbh->do($sql_command) if $sql_command =~ /\S/;
           # Execute the command if it's not empty
           my $stmt_changes = $dbh->rows();
           if ($stmt_changes > 0) {
              $db_changes += $dbh->rows();
           }
           $sql_command = '';
       }
   }
   close $fh;
   print $log "* Import completed: $db_changes inserts\n";
} else {
   print $log "* No import needed\n";
}

# add to asterisk's pjsip.webrtc.users.conf
sub add_sip_user {
   my $callsign = shift;
   $sip_user = create_uuid_as_string(UUID_RANDOM, "sip_user");
   $sip_user_compact = $sip_user;
   $sip_user_compact =~ s/-//g;

   $sip_pass = join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..16;

   my $pjsip_file = "/opt/telekinesis/etc/asterisk/telekinesis/user.$sip_user.conf";
   open(our $pj_fh, '>>', $pjsip_file) or die("Can't open pjsip.webrtc.users.conf for writing");
   print $log "adding pjsip account ($sip_user:$sip_pass) to asterisk\n";

   print $pj_fh "[webrtc_$sip_user_compact]\n";
   print $pj_fh "type=aor\n";
   print $pj_fh "max_contacts=5\n";
   print $pj_fh "remove_existing=yes\n\n";
   print $pj_fh "[webrtc_$sip_user_compact]\n";
   print $pj_fh "type=auth\n";
   print $pj_fh "username=$sip_user\n";
   print $pj_fh "password=$sip_pass\n\n";
   print $pj_fh "[webrtc_$sip_user_compact]\n";
   print $pj_fh "type=endpoint\n";
   print $pj_fh "aors=webrtc_$sip_user_compact\n";
   print $pj_fh "auth=webrtc_$sip_user_compact\n";
   print $pj_fh "dtls_auto_generate_cert=yes\n";
   print $pj_fh "webrtc=yes\n";
   print $pj_fh "context=telekinesisweb\n";
   print $pj_fh "disallow=all\n";
   print $pj_fh "allow=opus,ulaw,g722\n";
   close $pj_fh;

   # reload pjsip module in asterisk
   my $pid_file = 'var/run/asterisk/asterisk.pid';
   my $ast_running = 1;
   open my $pid_fh, '>>', $pid_file or $ast_running = 0;

   if ($ast_running) {
      my $astman = Asterisk::AMI->new(PeerAddr => '127.0.0.1',
                                      PeerPort => '5038',
                                      Username => 'logout-cgi',
                                      Secret => 'tShCawPy2EY0iLtB');
      die "Unable to connect to asterisk" unless ($astman);
      print $log "* reloading asterisk\n";
      my $action = $astman->send_action({ Action => 'Command', Command => 'module reload res_pjsip.so' });
   }
}

# Do not double hash the empty password...
my $hashed_pass;
if ($frm_pass eq "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855") {
   $hashed_pass = $frm_pass;
} else {
   $hashed_pass = unpack("H*", sha256($frm_pass));
}

print $log "* calling verify_callsign: $frm_callsign, $hashed_pass\n";
my ($db_callsign, $db_privileges, $db_disabled);
my $query = "SELECT callsign, privileges, disabled FROM telekinesis_users WHERE callsign = ? and password = ?;";
print $log "query: $query\n";

print $log "* prepare\n";
my $sth = $dbh->prepare($query) or die " - error: " . DBI->errstr . "\n";

print $log "* bind\n";
$sth->bind_columns(\$db_callsign, \$db_privileges, \$db_disabled) or die "- bind columns\n";

print $log "* query start\n";
eval {
   $sth->execute($frm_callsign, $hashed_pass) or die "db error:" . $DBI::errstr . "\n";
};
if ($@) {
   print $log "Error executing query: $@\n";
   print $log "DBI Error: " . $DBI::errstr . "\n";
}

print $log "* query done\n";

#my $rows = $sth->rows();
my $row = 0;
print $log "* verify_callsign:\n";
my $valid_login = 0;
my $reload_needed = 0;
my $rows = 0;
while ($sth->fetch) {
   $row++;
   $rows++;
   print $log "* row[$row]: $db_callsign, $db_privileges, $db_disabled\n";
   $valid_login = 1;
   $res_privileges = $db_privileges;
   last;
}

if ($rows > 0) {
   print $log "rows: $rows\n";
} elsif ($rows < 0) {
   # Check for fetch error (rows < 0 indicates an error)
   print $log "Error fetching results: " . $sth->errstr() . "\n";
} else {
   print $log "query returned 0 rows\n";
}

if ($valid_login && defined $db_disabled && $db_disabled == 1) {
   print $log "* login attempt from disabled account $frm_callsign, rejected!\n";
   $res_privileges = "false";
   $res_reason = "Login disabled!";
   $res_status = "FAILED";
} elsif ($valid_login) {
   $sess_token = create_uuid_as_string(UUID_RANDOM, "sesstok");
   $res_reason = "Access granted";
   $res_status = "OK";

   # Setup the SIP credentials
   add_sip_user($frm_callsign);

   if (not defined $db_privileges) {
      $db_privileges = "";
   }

   print $log "* login by $frm_callsign!\n";
   # XXX: insert into sessions db
   my $sess_query = "INSERT sessions ( callsign, token, created, last_active, sip_user, sip_pass, server ) VALUES ( ?, ?, ?, ?, ?, ?, ? );";
   # XXX: Insert their $sess_token and an expiry into the sessions.db
   $reload_needed = 1;
} else {
   print_status();
}

# XXX: Reload asterisk
if ($reload_needed) {
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
}   

# And send the json data to the client!
print_status();
