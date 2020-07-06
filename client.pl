#!/usr/bin/env perl

use Mojo::Base -strict;
use Mojo::UserAgent;
use File::Basename qw(dirname);
use Cwd qw(abs_path);
use lib ( dirname abs_path($0) ) . '';
use Local::DB;

sub store {
	my $data = shift;
	my $dbfile = shift;
	my $dbh = Local::DB->new($dbfile);
	$dbh->add($data->{timestamp}, $data->{ticker}{price});
	$dbh->close;
}

sub request {
	my $ua = Mojo::UserAgent->new;
	$ua->request_timeout(5);
	my $tx = $ua->get('https://api.cryptonator.com/api/ticker/btc-usd');
	return Cpanel::JSON::XS->new->utf8->decode( $tx->result->body );
}

my $dbfile = "xbtprice.sql";

my $loop = Mojo::IOLoop->singleton;

store( request(), $dbfile );

$loop->recurring(
	60 => sub {
		store(request(), $dbfile );
	}
);

$loop->start unless $loop->is_running;
