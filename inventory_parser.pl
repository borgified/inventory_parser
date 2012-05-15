#!/usr/bin/perl

use warnings;
use strict;
use Net::Telnet;

&main;

sub main{

	&login;

#	my $output="You have: an aquamarine potion, a blue bubbly potion, a brown bag, two dark
#  flasks, three sets of eye of newt, three golden daggers, a grey scroll, a
#  hammer of thunderbolts, two hazy potions, an ivory coffer, four wand of
#  the efreetis, two werewolf sire skulls.  Inventory weight is 227 lbs.
#(118 H 3 M):";

#	my @inventory=$output;
#	my $inventory=\@inventory;
#	&parse($inventory);

}

sub login{

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

#this is what the login looks like
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
		my $inv_ref=\@inventory;
		&parse($inv_ref);
	}
}

sub parse{
#You have: an aquamarine potion, a blue bubbly potion, two dark flasks, some
#  eye of newt, a golden dagger, three green potions, a hammer of
#  thunderbolts, two hazy potions, an ivory coffer, a verdant green scroll,
#  nine wand of the efreetis, three werewolf sire skulls.  Inventory weight
#  is 248 lbs.
#(120 H 3 M):

	my($inv_ref)=@_;

	my @inventory = @{$inv_ref};
	
	print "@inventory";

}
