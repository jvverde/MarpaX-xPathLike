#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = ("\n",",");

my $query = Data::pQuery->compile('*');
my @values1 = $query->process({fruit => 'bananas'})->getvalues();
print @values1;

my @values2 = $query->process({
	fruit => 'bananas', 
	vegetables => 'orions'
})->getvalues();
print @values2;

my @values3 = $query->process({
	food => {fruit => 'bananas'}
})->getvalues();
print Dumper @values3;
