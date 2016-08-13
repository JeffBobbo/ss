#!/usr/bin/perl

package BobboBot::ap;

use warnings;
use strict;

use BobboBot::users;

use JSON qw(from_json);
use LWP::Simple;

my $map = undef;
sub run
{
  if (!(-e 'universe.json'))
  {
    $map = updateData();
  }
  else
  {
    my $mtime = (stat('universe.json'))[8];
    if ($mtime + 86400 < time())
    {
      $map = updateData();
    }
    elsif (!defined $map)
    {
      open(my $fh, '<', 'universe.json');
      my $tmp = join('', <$fh>);
      close($fh);
      $map = from_json($tmp);
    }
  }

  my $arg = join(' ', @{$_[0]->{arg}});

  my $from;
  my $to;
  my $w4 = 0;
  {
    my $index = index($arg, '"');
    if ($index == -1)
    {
      return help();
    }
    $from = substr($arg, $index+1, index($arg, '"', $index+1) - $index - 1);
    $index = index($arg, '"', $index + length($from) + 2);
    $to = substr($arg, $index+1, index($arg, '"', $index+1) - $index - 1);
  }
  $w4 = 1 if ($arg =~ /-w4/);

  my $fromID = galID($from);
  my $toID = galID($to);

  if ($fromID == -1)
  {
    return "Failed to find starting location, `$from`.";
  }
  if ($toID == -1)
  {
    return "Failed to find destination location, `$to`.";
  }

  if ($fromID == $toID)
  {
    return 'You\'re already at your destination.';
  }

  my @r = @{route($fromID, $toID, $w4)};
  if (@r == 0)
  {
    return "No route from `$from` to `$to` found.";
  }

  my @ret;
  my $str = $from . ' to ' . $to . ' in ' . @r . ' jump' . (@r == 1 ? '' : 's') . '.';
  $str .= $map->{$r[0]}{n};
  for (my $i = 0; $i < @r; $i += 20)
  {
    my $k = $i + 20 < @r ? $i + 20 : @r;
    for (my $j = $i+1; $j < $k; ++$j)
    {
      if (length($str))
      {
        $str .= ' > '
      }
      $str .= $map->{$r[$j]}{n};
    }
    if ($k < @r)
    {
      $str .= ' >';
    }
    push(@ret, $str);
    $str = '';
  }
  return \@ret;
}

sub help
{
  return '!ap "[start]" "[end]" (-w4) - Calculates autopilot route to the end galaxy from the start galaxy. Supply `-w4` to use warp 4 shortcuts.';
}

sub auth
{
  return accessLevel('utils');
}

BobboBot::module::addCommand('ap', 'run', \&BobboBot::ap::run);
BobboBot::module::addCommand('ap', 'help', \&BobboBot::ap::help);
BobboBot::module::addCommand('ap', 'auth', \&BobboBot::ap::auth);

sub route
{
  my $from = shift();
  my $to = shift();
  my $w4 = shift() || 0;

  my %dist;
  my %prev;
  $dist{$from} = 0;
  $prev{$from} = undef;
  my @q;

  my @keys = keys(%{$map});
  for (my $i = 0; $i < @keys; ++$i)
  {
    my $v = $keys[$i];
    if ($v != $from)
    {
      $dist{$v} = 1000;
      $prev{$v} = undef;
    }
    push(@q, $v);
  }

  my @r;
  while (@q)
  {
    my $l = @q - 1;
    my $u = $q[$l];
    for (my $i = @q - 2; $i >= 0; --$i)
    {
      if ($dist{$q[$i]} < $dist{$u})
      {
        $u = $q[$i];
        $l = $i;
      }
    }
    if ($u == $to)
    {
      my $v = $to;
      while ($prev{$v})
      {
        unshift(@r, $v);
        $v = $prev{$v};
      }
      unshift(@r, $from);
      last;
    }

    splice(@q, $l, 1);

    my @links = @{$map->{$u}{w}};
    foreach my $link (@links)
    {
      next if (!$map->{$link});
      next if ($w4 == 0 && isW4($map->{$link}{n}));

      my $alt = $dist{$u} + 1;
      if ($alt < $dist{$link})
      {
        $dist{$link} = $alt;
        $prev{$link} = $u;
      }
    }
  }
  return \@r;
}

sub galID
{
  my $name = shift();

  foreach my $id (keys(%{$map}))
  {
    return $id if ($map->{$id}{n} eq $name);
  }
  return -1;
}

sub isW4
{
  my $n = shift();

  return 1 if ($n =~ /^Juxtaposition [A-Z0-9\-]+$/);
  return 1 if ($n =~ /^Concourse [A-Z0-9\-]+$/);
  return 1 if ($n =~ /^Subspace [A-Z0-9\-]+$/);
  return 0;
}

sub updateData
{
  my $tmp = get('http://starsonata.com/ss_api/universe.json');
  open(my $fh, '>', 'universe.json');
  print $fh $tmp;
  close($fh);
  return from_json($tmp);
}

1;
