#!/usr/bin/perl
use strict;
use Data::pQuery;

$\ = "\n";
my $pquery = Data::pQuery->new('a.b');
my $data = {a => { b => 'bb'}, c => 'cc'};
my $results = $pquery->execute($data);
my @values = $results->getvalues();
print $values[0];				#outputs 'bb'
my @refs = $results->getrefs();
${$refs[0]} = 'new value';
print $data->{a}->{b};				#outputs 'new value'
