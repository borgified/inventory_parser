#!/usr/bin/perl

use warnings;
use strict;
use Net::Telnet;

&main;

sub main {

#	&login;		#tmp uncommented
#	&parse;		


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
				&parse_items($inventory);
		}
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
						}
				}
		}
}

