#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = ("\n",",");

my $query = Data::pQuery->compile('*');
my @values1 = $query->data({fruit => 'bananas'})->getvalues();
print @values1;

my @values2 = $query->data({
	fruit => 'bananas', 
	vegetables => 'orions'
})->getvalues();
print @values2;

my @values3 = $query->data({
	food => {fruit => 'bananas'}
})->getvalues();
print Dumper @values3;
