#!/usr/bin/env perl

use Mojo::Base -strict;
use Mojo::UserAgent;
use File::Basename qw(dirname);
use JSON;
use POSIX qw(strftime);
use Scalar::Util qw(looks_like_number);
use Cwd qw(abs_path);
use lib ( dirname abs_path($0) ) . '';
use Local::DB;

sub init_local_data {
	my ($file, $data) = @_;
	open(my $fh, "<", $file)
		|| die "can't open $file: $!\n";
	while (<$fh>) {
		chomp;
		my ($key, $val) = split(/,/, $_);
		$data->{$key} = $val;
	}
	return 1;
}


sub store {
	my $price = shift;
	my $dbfile = shift;
	return 0 unless $price;
	my $dbh = Local::DB->new($dbfile);
	$dbh->add(strftime("%s", localtime), $price);
	$dbh->close;
}

sub price {
	my $data = shift;

# handling API differences
	my $price = do {
		if ($data->{h} && $data->{l}) {
			eval { ($data->{h}->[0] + $data->{l}->[0]) / 2 }
		}
		elsif ($data->{USD}) { $data->{USD}->{"15m"} }
		elsif ($data->{ticker}) { $data->{ticker}->{price} }
		else { "NaN" }
	};

	if ($price =~ m/^\d/ && looks_like_number($price)) {
		return $price;
	}
	else {
		return 0;
	}
}

sub request {
	my ($urls, $token) = @_;
	my $result;
	
# conveniently, reverse alphabetic order is
# the priority in which I want the APIs called
	for my $key (reverse(sort(keys %{$urls}))) {
		my $url = $urls->{$key};
		if ($token->{$key}) {
			my $to = strftime("%s", localtime);
			my $from = $to - 300;
			$url .= "&from=$from" . "&to=$to";
			$url .= "&token=" . $token->{$key};
		}
		my $ua = Mojo::UserAgent->new;
		$ua->request_timeout(5);
		my $tx = $ua->build_tx(GET => $url);
		$tx->req->headers->accept('application/json');
		$tx = $ua->start($tx);
		if ($tx->res->error) {
			warn $tx->res->error->{message};
			next;
		}
# moving right on to the next API if response is not good JSON
		$result = eval { JSON->new->utf8->decode($tx->result->body) };
		last unless $@;
	}
	return price($result) || 0;
}

my $dbfile = "xbtprice.sql";

# API key
my %token;
my $ok = init_local_data("token.txt", \%token);
die "Can't init API key\n" unless $ok;

# Upstream sources
my %urls;
$ok = init_local_data("sources.txt", \%urls);
die "Can't load sources\n" unless $ok;

my $loop = Mojo::IOLoop->singleton;

# block until time is right
while (strftime("%M", localtime) % 5) { sleep 5 }
my $ret = store(request(\%urls, \%token), $dbfile);
warn "No price data! " . strftime("%F", localtime) . "\n" unless $ret;

$loop->recurring(
	300 => sub {
		$ret = store(request(\%urls, \%token), $dbfile );
		warn "No price data! " . strftime("%F", localtime) . "\n" unless $ret;
	}
);

$loop->start unless $loop->is_running;
