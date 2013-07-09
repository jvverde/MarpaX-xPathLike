#!/usr/bin/perl
use strict;
use Data::pQuery;

($\,$,) = ("\n",",");
my $query = Data::pQuery->compile('a.*');
my $data = {a => { b => 'bb', c => 'cc'}, aa => 'aa'};
my $results = $query->process($data);
my @values = $results->getvalues();
print @values;				#outputs 'bb,cc'
my @refs = $results->getrefs();
${$refs[0]} = 'new value';
print $data->{a}->{b};			#outputs 'new value'
