#!/usr/bin/perl

use warnings;
use strict;
use Net::Telnet;

my $t = new Net::Telnet (Timeout => 10, Port => 4040,);

$t->open("isengard.nazgul.com");

#Please enter name:
#Please enter password:
#(23 H 2 M):

$t->waitfor('/Please enter name:/');
$t->print("druuge");


$t->waitfor('/Please enter password:/');
$t->print("");


my @lines = $t->cmd("i");

print @lines;
