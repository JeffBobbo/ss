#!/usr/bin/perl

package BobboBot::link;

use warnings;
use strict;

use BobboBot::users;
use POSIX;

my %links = (
  ticket => 'http://support.starsonata.com',
  forum => 'http://forum.starsonata.com',
  wiki => 'http://wiki.starsonata.com',
  map => 'http://starsonata.com/map',
  discord => 'https://discord.gg/0uO2ih0jVC4vLSut';
);

sub run
{
  my $arg = join(' ', @{$_[0]->{arg}});

  if ($links{$arg})
  {
    return $links{$arg};
  }

  my @items = keys(%links);
  my $str = 'Links: ' . $items[0];
  for (my $i = 1; $i < @items; ++$i)
  {
    $str .= ', ' . $items[$i];
  }
  return $str;
}

sub help
{
  return '!link (link) - Links!.';
}

sub auth
{
  return accessLevel('utils');
}

BobboBot::module::addCommand('link', 'run', \&BobboBot::link::run);
BobboBot::module::addCommand('link', 'help', \&BobboBot::link::help);
BobboBot::module::addCommand('link', 'auth', \&BobboBot::link::auth);

1;
