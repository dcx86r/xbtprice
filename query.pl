#!/usr/bin/env perl

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib ( dirname abs_path($0) ) . '';
use Local::DB;
use Data::Dumper;

my $dbfile = $ARGV[0];
die "provide filename as argument\n" unless $ARGV[0];
my $dbh = Local::DB->new($dbfile);
my @rows = $dbh->fetch("day");
$dbh->close;
print Dumper @rows;
