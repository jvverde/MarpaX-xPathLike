#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = (qq|\n|, q|,|);
my $data = Data::pQuery->data({
	food =>{
		fruit => [qw|bananas apples oranges pears|], 
		vegetables => [qw|potatoes carrots tomatoes onions|]
	},
	drinks =>{
		q|soft drinks| => [qw|Soda Coke|]
	} 
});

print $data->query('**{name() eq "fruit"}[..]')->getvalues();
#bananas,apples,oranges,pears 
print $data->query(q|**{name() eq 'fruit'}[..]{value() ~ "p"}|)->getvalues();
#apples,pears 
print $data->query(q|drinks/"soft drinks"[0]|)->getvalues();
#Soda
print $data->query(q|drinks/'soft drinks'[1]|)->getvalues();
#Coke

