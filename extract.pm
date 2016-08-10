#!/usr/bin/perl

package BobboBot::extract;

use warnings;
use strict;
use BobboBot::users;

my @resource = ("smidgen", "little", "bit", "bunch", "a lot", "plenty", "loads");

sub run
{
  my $amount = join(' ', @{$_[0]->{arg}});

  $amount =~ s/["']//g; # remove any quotes

  if (!defined $amount || $amount eq '')
  {
    return 'No resource abdundance.';
  }

  if ($amount eq 'list')
  {
    my $ret = 'Possible abdundencies: ';
    $ret .= '"' . $resource[0] . '"';
    for (my $i = 1; $i < @resource; $i++)
    {
      $ret .= ', "'. $resource[$i] . '"';
    }
    return $ret . '.';
  }

  my $min = 0;
  my $i;
  for ($i = 0; $i < @resource; $i++)
  {
    $min = $min << 1 || 1;
    last if (lc($amount) eq $resource[$i]);
  }
  if ($i == @resource)
  {
    return 'Unknown resource abdundance: ' . $amount . '.';
  }
  return 'You can equip ' . ($min != 1 ? $min + 1 : $min) . ' to ' . ($min << 1) . ' extractors.';
}

sub help
{
  return ['!extract [abdundance] - Tells you how many extractors you can equip for abdundance.',
          '!extract list - List of possible abdundencies.'];
}

sub auth
{
  return accessLevel('utils');
}

BobboBot::module::addCommand('extract', 'run', \&BobboBot::extract::run);
BobboBot::module::addCommand('extract', 'help', \&BobboBot::extract::help);
BobboBot::module::addCommand('extract', 'auth', \&BobboBot::extract::auth);

1;
