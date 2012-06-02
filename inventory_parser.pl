#!/usr/bin/perl

use warnings;
use strict;
use Net::Telnet;
use DBI;

&main;

sub main {

### THE PLAN
#1. get login credentials

#2. get inventory

#3. store results


	my $mud_ip = "isengard.nazgul.com";
	my $mud_port=4040;

	my $login = &retrieve_login_info;

	foreach my $name (keys %{$login}){
		my $inventory = &login($mud_ip,$mud_port,$name,$$login{$name});
		print "-----------------\n";
		print "$inventory\n";
		print "-----------------\n";
		my $items_href=&parse_items($inventory);
		&store_results($items_href);
	}
}

#input: hash ref containing item's quantity and name
#output: none

#retrieves items from hash and stores it into a mysql database

sub store_results {
	my($items_href)=@_;
	#print %$items_href;
	
#$hash{'item_name'}='quantity';

	my $my_cnf = '/secret/my_cnf.cnf';

#my_cnf.cnf looks something like this
#[inventory_parser]
#host            = localhost
#database        = xxxxxx
#user            = xxxxxx
#password        = xxxxxx

	my $dbh = DBI->connect("DBI:mysql:"
			. ";mysql_read_default_file=$my_cnf"
			.';mysql_read_default_group=inventory_parser',
			undef,
			undef
			) or die "something went wrong ($DBI::errstr)";

	# grant select, insert, update on isengard.* to dm_isengard@'localhost' identified by 'pwd';
	# flush privileges;
	my $sql="CREATE TABLE IF NOT EXISTS inventory_parser(id INT NOT NULL AUTO_INCREMENT, PRIMARY KEY(id),char_name VARCHAR(20), location VARCHAR(40), current_weight INT(3), item_name VARCHAR(50), item_quantity INT(4), check_in_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP)";
	my $sth=$dbh->prepare($sql);
	$sth->execute();

	foreach my $k (sort keys %$items_href){
		#print "$k: $$items_href{$k}\n";
		my $item_quantity="$$items_href{$k}";
		$k=~s/\'/\\'/;
		#$k=~s/\)/)/;
		#$k=~s/\(|\'|\)/\\/g;
		print "$item_quantity : `$k`\n";
		
		my $sql2="INSERT INTO inventory_parser(item_name,item_quantity) VALUES (\'$k\',\'$item_quantity\')";
		my $sth2=$dbh->prepare($sql2); 
		$sth2->execute();

	}
	$dbh->disconnect;
	exit;

#check if table exists, if not create
#insert ... on duplicate key update: http://dev.mysql.com/doc/refman/4.1/en/insert-on-duplicate.html
#inserting multiple records: http://www.electrictoolbox.com/mysql-insert-multiple-records/
#potential table columns: char name, location, current weight, item name, item quantity, last checked in date

}



#input: login info (text file or database)
#output: \$roster{$name}=$password

#can be from a file or from database
#read list of storage chars and passwords
#format:
#comments are lines starting with # (they are ignored)
#one char name/password per line like this:
#char_name:password
sub retrieve_login_info {

	open(ROSTER,"/secret/inventory_parser_secret.pl") or die "cant open secret file";

	my %roster;

	while(defined(my $line=<ROSTER>)){
		if($line =~ /^#/){
			next;
		}else{
			chomp($line);
			my ($name,$password)=split(/:/,$line);
			$roster{$name}="$password";
		}
	}

	return \%roster;

}


#input: $ip $port $name $password
#output: \@inventory
sub login{

	my($mud_ip,$mud_port,$name,$password)=@_;

	my $t = new Net::Telnet (Timeout => 10, Port => $mud_port,);

	$t->open($mud_ip);

#this is what the login looks like
#Please enter name:
#Please enter password:
#(23 H 2 M):

	$t->waitfor('/Please enter name:/');
	$t->print($name);


	$t->waitfor('/Please enter password:/');
	$t->print($password);

	$t->waitfor('/\(\d+ H \d+ M\):/');
	$t->print("rem all");
	$t->waitfor('/\(\d+ H \d+ M\):/');

TRYAGAIN:

	$t->print("i");
	my @inventory = $t->waitfor('/\(\d+ H \d+ M\):/');

	my $items=&is_valid(\@inventory);
	if($items ne 'error'){
		return $items;
	}else{
		goto TRYAGAIN;
	}
}

#input can be corrupted if the inventory listing gets mixed up with
#other text output. like when a mob walks into the room just at the right time

#input: inventory listing
#output: $items string if ok, 0 if corrupted
sub is_valid{
	my $result="";
	my ($inv_aref)=@_;

#reconstruct inventory lines
	foreach my $line (@$inv_aref){
		$line=~s/\(\d+ H \d+ M\)://g;
			$line=~s/\n|\r//g;
			 $result=$result.$line;
	}

	$result =~ /You have: (.*)\.  Inventory weight is (\d+) lbs./;
	my $items = $1;
	if($items !~ /\.|just arrived/){
		return $items;
	}
	return "error";
}



sub parse_items{
	my %keywords;
	my %output;

	$keywords{'some'}=1;
	$keywords{'a'}=1;	
	$keywords{'an'}=1;	
	$keywords{'the'}=1;
	$keywords{'two'}=2;
	$keywords{'three'}=3;
	$keywords{'four'}=4;
	$keywords{'five'}=5;
	$keywords{'six'}=6;
	$keywords{'seven'}=7;
	$keywords{'eight'}=8;
	$keywords{'nine'}=9;
	$keywords{'ten'}=10;
	$keywords{'eleven'}=11;
	$keywords{'twelve'}=12;
	$keywords{'thirteen'}=13;
	$keywords{'forteen'}=14;
	$keywords{'fifteen'}=15;
	$keywords{'sixteen'}=16;
	$keywords{'seventeen'}=17;
	$keywords{'eighteen'}=18;
	$keywords{'nineteen'}=19;

	my($parse_items)=@_;

	$parse_items=~s/,\s+/,/g;
	$parse_items=~s/\s+/ /g;
	$parse_items=~s/\s+$//g;
	$parse_items=~s/sets of //g;

	my @inventory=split(/,/,$parse_items);

	foreach my $item(@inventory){
		foreach my $k(keys %keywords){
			if($item=~/^$k\s(.*)/){
				print "$item ==> [$keywords{$k} $1]\n";
				$output{$1}="$keywords{$k}";
			}
		}
	}
	return \%output;
}

#input: the plural form of some noun
#output: the singular form of the same noun
sub unpluralize {
	my $string=(@_);
}

#select a storage char that hasnt been logged in for X number of days and sync up changes
sub refresh_database {

}
