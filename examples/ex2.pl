#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = ("\n",",");

my $process = Data::pQuery->process({
	food => { 
		fruit => 'bananas',
		vegetables => 'unions'
	},
	drinks => {
		wine => 'Porto',
		water => 'Evian'
	}
});
my @values1 = $process->compile('*.*')->getvalues();
print @values1; # Evian,Porto,bananas,unions

my @values2 = $process->compile('*.wine')->getvalues();
print @values2;
Porto

my @values3 = $process->compile('*{fruit}.*')->getvalues();
print @values3;
bananas,unions

my @values4 = $process->compile('*.*{value() ~ /an/}')->getvalues();
print @values4;
Evian,bananas

