#!/usr/bin/perl

use warnings;
use strict;
use Net::Telnet;

#read list of storage chars and passwords
#format:
#comments are lines starting with # (they are ignored)
#one char name/password per line like this:
#char_name:password


open(ROSTER,"/secret/inventory_parser_secret.pl") or die "cant open secret file";

my %roster;
my $mud_ip="isengard.nazgul.com";
my $mud_port=4040;

while(defined(my $line=<ROSTER>)){
	if($line =~ /^#/){
		next;
	}else{
		chomp($line);
		my ($name,$password)=split(/:/,$line);
		$roster{$name}="$password";
	}
}

foreach my $name (keys %roster){

	my $t = new Net::Telnet (Timeout => 10, Port => $mud_port,);

	$t->open($mud_ip);

#this is what the login looksl like
#Please enter name:
#Please enter password:
#(23 H 2 M):

	$t->waitfor('/Please enter name:/');
	$t->print($name);


	$t->waitfor('/Please enter password:/');
	$t->print($roster{$name});

	$t->waitfor('/\(23 H 2 M\):/');
	$t->print("rem all");
	$t->waitfor('/\(23 H 2 M\):/');
	$t->print("i");
	my @inventory = $t->waitfor('/\(23 H 2 M\):/');
	print "@inventory";
}
