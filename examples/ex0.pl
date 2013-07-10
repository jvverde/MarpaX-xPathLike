#!/usr/bin/perl
use strict;
use Data::pQuery;

($\,$,) = ("\n",",");
my $query = Data::pQuery->compile('a.*');
my $data = {
	a => { 
		b => 'bb', 
		c => 'cc'
	}, 
	aa => 'aa'
};
my $results = $query->data($data);
my @values = $results->getvalues();
print @values;				#outputs 'bb,cc'
my $ref = $results->getref();
$$ref = 'new value';
print $data->{a}->{b};			#outputs 'new value'
