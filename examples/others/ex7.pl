#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = (qq|\n|, q|,|);
my $data = Data::pQuery->data({
	options =>[{
		fruit => [qw|bananas apples|], 
		vegetables => [qw|potatoes carrots|]
	},{
		seeds => [qw|peanut nuts|],
		vegetables => [qw|beans peas|]
	}]
});

print $data->query(q|*[..]{seeds}/vegetables[0]|)->getvalues();

