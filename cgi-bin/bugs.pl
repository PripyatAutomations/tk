#!/usr/bin/perl
use strict;
use warnings;
use CGI;
use UUID::Tiny ':std';
use File::Find;
use File::Basename;
use Cwd 'abs_path';

my $report_type = "db";	# else "mail"

print "Content-type: text/html\n\n";

my $cgi = CGI->new();
my $frm_project = $cgi->param("project");
my $frm_act = $cgi->param("act");

if (!defined($frm_act)) {
   $frm_act = "list";
}

if (!defined($frm_project)) {
   my $t = dirname(abs_path($0));
   my @parts = split('/', $t);
   if (@parts > 1) {
      $frm_project = $parts[@parts - 2];
   } else {
      $frm_project = 'bugs.pl';
   }
}

my $bugs = 0;

if ($frm_act eq "list") {
   if ($bugs == 0) {
      print "No bugs have been reported yet for $frm_project<br/>\n";
      print "Report one <a href=\"/bugreport.html\">here</a>\n";
   }
} elsif ($frm_act eq "report") {
   print "Bug reporting is work in progress... Try back soon!\n";
   # xxx: email or sqlite3?
   if ($report_type eq "db") {
      # XXX: Write the report to db/bugs.db
   } elsif ($report_type eq "mail") {
      # XXX: Implement email support
   }
}
