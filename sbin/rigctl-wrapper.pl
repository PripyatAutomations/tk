#!/usr/bin/perl
#
# Here we connect to our configured radios via rigctld interface and expose them over websocket to the html5 view
#
# XXX: We need to check the session database to make sure user is authorized
use strict;
use warnings;
use Scalar::Util;
use HTTP::Request::Common;
use IO::Async::Loop;
use IO::Async::Timer::Countdown;
use IO::Async::Stream;
use IO::Handle;
use Net::Async::WebSocket::Client;
use Net::WebSocket::Server;
use JSON;
use Data::Dumper;
use Hamlib;
use MIME::Base64;
use POSIX qw(strftime);
use RPC::XML qw(:types);
use RPC::XML::Client;
use LWP;
use LWP::UserAgent;
use URI::Escape;
use Time::HiRes qw(gettimeofday tv_interval usleep);
use DBI;

STDOUT->autoflush(1);		# disable linebuffering on output, so we can log easier
my $app_name = "rgictl-wrapper";
my $VERSION = "20231109.01";

# Log levels for messages
my $LOG_NOISE = 7;              # extra noisy debugging
my $LOG_DEBUG = 6;              # normal debugging
my $LOG_INFO = 5;               # informational messages (noisy)
my $LOG_WARN = 4;               # warnings
my $LOG_AUDIT = 3;              # auditing events
my $LOG_BUG = 2;                # bugs
my $LOG_FATAL = 1;              # fatal errors

my $cfg = {
    "loglevel" => $LOG_DEBUG,
    "hamlib" => {
       "loglevel" => "debug"
    },
    "station" => {
       "callsign" => "N0CALL",
       "default_mode" => "phone",
       "gridsquare" => "FN19",
    }
};

our @channels_60m = ( '5330500', '5346500', '5357000', '5371500', '5403500' );

my $state = {
   "users" => 1,
   "radios" => {
      "radio0" => {
         "active_vfo" => $Hamlib::RIG_VFO_A,
         "bridge_id" => "",
         "debug_level" => "bug",
         "dialstring" => "/dial 0\@127.0.0.1",        # SIP address to call into
         "vfo_a" => {
            'freq' => 7074000,
            'if_shift' => 0,                     # IF shift
            'mode' => 'D-U',
            'width'=> 3000
         },
         'vfo_b' => {
            'freq' => 14074000,
            'if_shift' => 0,                     # IF shift
            'mode' =>'D-U',
            'width'=> 3000
         },
         "model" => $Hamlib::RIG_MODEL_NETRIGCTL,
         "passbands" => {
            "am" => 6000,
            "cw" => 1000,
            "data" => 3000,
            "fm" => 12000,
            "ssb" => 3000
         },
         "ptt_start" => 0,                    # Time TOT started
         "ptt_blocked" => 1,
         "ptt_active" => 0,
         "power" => 50,
         "power_divider" => 100,		# hamrig power divider (max power?)
         "station_mode" => "phone",           # station mode
         "tuning_limit_low" => 3000,
         "tuning_limit_high" => 56000000,
         "using_vox" => 0
      }
   }
};
my $radio = $state->{'radios'}{'radio0'};

#######################################

sub Log {
#   # Capture the log_type and level from arguments
   my $log_type = shift;
   my $log_level = shift;

   if ($cfg->{'loglevel'} < $log_level) {
      return 0;
   }

   my $datestamp = strftime("%Y/%m/%d %H:%M:%S", localtime);
   my $lvl;

   if ($log_level == $LOG_NOISE) {
      $lvl = "noise";
   } elsif ($log_level == $LOG_DEBUG) {
      $lvl = "debug";
   } elsif ($log_level == $LOG_INFO) {
      $lvl = "info";
   } elsif ($log_level == $LOG_WARN) {
      $lvl = "warn";
   } elsif ($log_level == $LOG_AUDIT) {
      $lvl = "AUDIT";
   } elsif ($log_level == $LOG_BUG) {
      $lvl = "BUG";
   } elsif ($log_level == $LOG_FATAL) {
      $lvl = "FATAL";
   } else {
      $lvl = "UNKNOWN";
   }
   print $datestamp . " [$log_type/$lvl]";

   foreach my $a(@_) {
      print " " . $a;
   }
   print "\n";
}

sub hamlib_debug_level {
   my $new_lvl = $_[0];

   if ($new_lvl =~ m/none/i) {
     return $Hamlib::RIG_DEBUG_NONE;
   } elsif ($new_lvl =~ m/bug/i) {
     return $Hamlib::RIG_DEBUG_BUG;
   } elsif ($new_lvl =~ m/err/i) {
     return $Hamlib::RIG_DEBUG_ERR;
   } elsif ($new_lvl =~ m/warn/i) {
     return $Hamlib::RIG_DEBUG_WARN;
   } elsif ($new_lvl =~ m/verbose/i) {
     return $Hamlib::RIG_DEBUG_VERBOSE;
   } elsif ($new_lvl =~ m/trace/i) {
     return $Hamlib::RIG_DEBUG_TRACE;
   } elsif ($new_lvl =~ m/cache/i) {
     return $Hamlib::RIG_DEBUG_CACHE;
   } else {
     return $Hamlib::RIG_DEBUG_VERBOSE;
   }
}

Log "core", $LOG_INFO, "$app_name $VERSION starting";

# Configure hamlib generic stuff
Hamlib::rig_set_debug(hamlib_debug_level($cfg->{'loglevel'}));

sub radio_get_freq {
   my $vfo = $radio->{'active_vfo'};
   if ($vfo eq $Hamlib::RIG_VFO_A) {
      return $radio->{'freq_a'} = $radio->get_freq();
   } elsif ($vfo eq $Hamlib::RIG_VFO_B) {
      return $radio->{'freq_b'} = $radio->get_freq();
   } elsif ($vfo eq $Hamlib::RIG_VFO_C) {
      return $radio->{'freq_c'} = $radio->get_freq();
   }
}

sub radio_set_freq {
   my $freq = $_[0];
   my $chan_id = $_[1];
   my $autoreadback = 1;
   my $vfo = $radio->{'active_vfo'};

   if ($_[2]) {
      $autoreadback = 1;
   }

   if ($vfo eq $Hamlib::RIG_VFO_A) {
      $radio->set_freq($Hamlib::RIG_VFO_A, $freq);
      $radio->{'vfo_a'}{'freq'} = $freq;
   } elsif ($vfo eq $Hamlib::RIG_VFO_B) {
      $radio->set_freq($Hamlib::RIG_VFO_B, $freq);
      $radio->{'vfo_b'}{'freq'} = $freq;
   } elsif ($vfo eq $Hamlib::RIG_VFO_C) {
      $radio->set_freq($Hamlib::RIG_VFO_C, $freq);
      $radio->{'vfo_c'}{'freq'} = $freq;
   }
}

sub radio_readback_freq {
   my $vfo_freq;
#   my $ab = $alert_bridge->{'id'};

   $vfo_freq = radio_get_freq();
   Log "dtmf", $LOG_DEBUG, "Readback [VFO" . $radio->{'active_vfo'} . "] freq: " . $vfo_freq/1000;
#   ari_speak_number($ab, ($vfo_freq/1000) . "khz");

   return $vfo_freq;
}

sub radio_readback_output_power {
#   ari_speech($chan_id, "output_power");
#   ari_speak_number($chan_id, int($radio->{'power'}) . "w");
}

sub radio_readback_swr {
   my $val = shift;
   my $swr = 4.42595 * $val + 0.858932
}
sub radio_readback_mode {
   my ($mode, $width) = $radio->get_mode();
   my $new_mode = Hamlib::rig_strrmode($mode);
   Log "dtmf", $LOG_INFO, "Readback mode: $new_mode $width";

   if ($new_mode =~ m/^pkt/i) {
      $new_mode = 'data';
   }

#   ari_speech($chan_id, lc($new_mode));
#   ari_speak_number($chan_id, $tuning_step_multipliers[$tuning_step_multiplier] . "hz");
}

sub radio_refresh() {
   radio_get_freq();
}

my @status_poll_radios = ( "radio0" );
my @status_poll_radio_items = ( "active_vfo", "vfo_a", "vfo_b", "power", "ptt_active", "ptt_blocked", "station_mode", "using_vox" );
my @status_poll_main_items = ( "users" );

use JSON::XS;
use Data::Structure::Util qw/unbless/;


sub serialize {
  my $obj = shift;
  my $class = ref $obj;
  unbless $obj;
  my $rslt = encode_json($obj);
  bless $obj, $class;
  return $rslt;
}

sub deserialize {
  my ($json, $class) = @_;
  my $obj = decode_json($json);
  return bless($obj, $class);
}

# XXX: dec/increment the user counter as needed
my $ws = Net::WebSocket::Server->new(
   listen => 18001,
   tick_period => 1,
   on_tick => sub {
   my ($serv) = @_;

   my $data = {
      "time" => time,
   };

   # add main state items to propogate first
   for my $cur_item (@status_poll_main_items) {
      my $rval = $state->{$cur_item};
      $data->{$cur_item} = $rval;
   }

   # then iterate over all available radios (XXX: This should be only the requested radios)
   for my $cur_radio (@status_poll_radios) {
      for my $item (@status_poll_radio_items) {
         my $rval;
         if ($item =~ m/^vfo_/) {
            # This is ugly, but otherwise, it breaks :(
            $rval = from_json(serialize($state->{'radios'}{$cur_radio}{$item}));
         } else {
            $rval = $state->{'radios'}{$cur_radio}{$item};
         }
         $data->{$cur_radio}{$item} = $rval;
      }
   }
   my $msg = serialize $data;
   $_->send_utf8($msg) for $serv->connections;
}, )->start;
