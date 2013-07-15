#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = (qq|\n|, q|,|);
my $data = Data::pQuery->data({
	options =>[{
		fruit => [qw|bananas apples|], 
		vegetables => [qw|potatoes carrots spinach|]
	},{
		seeds => [qw|peanut nuts|],
		vegetables => [qw|beans peas|]
	}]
});

#print $data->query(q!**{count([..]|*|a) == 3}[0]!)->getvalues();
print $data->query(q!x|[3]|f|/b[3]/c!)->getvalues();

