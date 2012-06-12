#!/usr/bin/env perl

use warnings;
use strict;
use DBI;

&main;

sub main {

	my $my_cnf = '/secret/my_cnf.cnf';
	my $dbh = DBI->connect("DBI:mysql:"
		. ";mysql_read_default_file=$my_cnf"
		.';mysql_read_default_group=inventory_parser',
		undef,
		undef
		) or die "something went wrong ($DBI::errstr)";
	
	my $sql = "select item_name,item_quantity from inventory_parser";
	my $sth=$dbh->prepare($sql);
	$sth->execute();
	
	while(my @line=$sth->fetchrow_array()){
		print "$line[1] $line[0]\n";
	}
}
