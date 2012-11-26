#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket;
use constant OFF => 0;
use constant ON => 1;

use constant DEBUG => 0;

my %_SETTINGS = (
  # Configurable
  'network'   => 'YOUR NETWORK',
  'port'      => 6667,
  'nickname'   => 'USERNAME',
  'channel'   => '#DEFAULT_CHANNEL'
);
my $ready = OFF;

my $sock = new IO::Socket::INET "$_SETTINGS{'network'}:$_SETTINGS{'port'}"
or die "Cannot create connection to $_SETTINGS{'network'} on port $_SETTINGS{'port'}: $!\n";

sendPayload("USER", "$_SETTINGS{'nickname'} "x3 . ":$_SETTINGS{'nickname'}");
sendPayload("NICK", $_SETTINGS{'nickname'});

while (my $text = <$sock>) {

  print $text if DEBUG == ON;
  chomp $text;

  my ($host, $username, $said) = (get_host($text), get_username($text), get_said($text));
  my @incoming = split(/ /, $text);

  if ($incoming[1] and ($incoming[1] eq "376" or $incoming[1] eq "422")) {
    sendPayload("JOIN", $_SETTINGS{'channel'});
  }

  if ($incoming[1] eq "366") {
    $ready = ON;
  }

  if ($incoming[0] eq "PING") {
    sendPayload("PONG", $incoming[1]);
    next;
  }

  chomp($said);

  next if $incoming[1] ne "PRIVMSG";

  # Log
  open CORPUS, ">>logs/" . get_date() . ".log";
  print CORPUS get_time() . " " . $username . ": " . $said . "\n";
  close CORPUS;

}

# Functions

sub sendPayload {

  my $p = join (' ', @_);

  print "[>] " . $p . "\n" if DEBUG == 1;
  print $sock $p . "\r\n";

}

sub get_username {
  return substr($_[0], 1, index($_[0], "!") - 1);
}

sub get_host {
  return substr($_[0], index($_[0], "!") + 1, index($_[0], " ") - index($_[0], "!") - 1);
}

sub get_said {
  my $offset = length(get_username($_[0])) + length(get_host($_[0])) + length("PRIVMSG") + length($_SETTINGS{'channel'}) + 6;
  if (length($_[0]) >= $offset) {
    my $said = substr($_[0], $offset);
    $said = substr($said, 0, length($said) - 1);
    return $said;
  } else {
    return "x";
  }
}

sub get_date {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

  return (1900 + $year) . "_" . $mon . "_" . $mday;
}

sub get_time {
  my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);

  return $hour . ":" . $min . ":" . $sec;
}

