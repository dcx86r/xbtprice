package Local::DB;

use strict;
use warnings;
use DBD::SQLite;
use POSIX qw(strftime);

my $init_db = sub {
	my $self = shift;
	(my $db_table = q{
		CREATE TABLE data (
			time INT NOT NULL,
			price REAL NOT NULL
		)
	}) =~ s/^\s*//mg;
	$self->{dbh}->do($db_table);
	return $self;
};

sub add {
	my ($self, $utm, $price) = @_;
	my $statement = "INSERT INTO data (time, price) VALUES (?, ?)";
	my $sth = $self->{dbh}->prepare($statement);
	$self->{dbh}->begin_work;
	$sth->execute($utm, $price);
	$sth->finish;
	$self->{dbh}->commit;
}

sub fetch {
# valid period is minute or day
	my ($self, $period) = @_;
	my %row;
	my @rows;
	my $statement = "SELECT time, printf(\"%.2f\", price) AS price from data ";
	$statement .= "WHERE time BETWEEN ? AND ? ORDER BY time DESC";
	my $sth = $self->{dbh}->prepare($statement);
	return "no period requested" unless $period;
# time frame for query
	my $now = POSIX::strftime "%s", localtime;
	my $last; 
	$last = $now - 60 if $period eq "minute";
	$last = $now - 86400 if $period eq "day";
	$self->{dbh}->begin_work;
	$sth->execute($last, $now);
	$sth->bind_columns( \( @row{ @{$sth->{NAME_lc} } } ));
	while ($sth->fetch) {
		push @rows, [ $row{time}, $row{price} ];
	}
	$sth->finish;
	$self->{dbh}->commit;
	return @rows;
}

sub close {
	my $self = shift;
	$self->{dbh}->disconnect;
	return 1;
}

sub new {
	my ($class, $path) = @_;
	$path =~ s/\s+/_/g;
	my $self = bless {
		dbh => DBI->connect("dbi:SQLite:dbname=$path","","",{
			AutoCommit=>1,
			RaiseError=>1,
			PrintError=>0,
			sqlite_unicode=>1
		})
	}, $class;
	$init_db->($self) if -z $path;
	return $self;
}

1;
