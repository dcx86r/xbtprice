#!/usr/bin/env perl

use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib ( dirname abs_path($0) ) . '';
use Local::DB;
use JSON;
use Mojolicious::Lite;

my $dbfile = $ARGV[0];
die "provide filename as argument\n" unless $ARGV[0];

sub fetch {
	my $dbfile = shift;
	my $dbh  = Local::DB->new($dbfile);
	my @rows = $dbh->fetch("day");
	$dbh->close;
	my @aoh;
	for my $row (@rows) {
		push @aoh, { time => @$row[0], value => (0 + @$row[1]) };
	}
	return JSON->new->encode(\@aoh);
}

get '/' => sub {
	my $c = shift;
	$c->res->headers->access_control_allow_origin('*');
	$c->render(text => fetch($dbfile), format => 'json');
};

#app->start( 'daemon', '-l', 'http://*:3000' );
app->start('daemon', '-m', 'production', '-l', 'http+unix://%2Ftmp%2Fapp.sock', '-p');
