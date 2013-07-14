#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = (qq|\n|, q|,|);
my $d = {
	food => {
		fruit => q|bananas|, 
		vegetables => [qw|potatoes  carrots tomatoes onions|]
	}
};
my $data = Data::pQuery->data($d);

my $food = $data->query('/food')->getref(); 
$$food->{drinks} = q|no drinks|; 

my $fruit = $data->query('/food/fruit')->getref();
$$fruit = 'pears';

my $vegetables = $data->query('/food/vegetables')->getref(); 
push @$$vegetables, q|garlic|;

my $vegetable = $data->query('/food/vegetables[1]')->getref();
$$vegetable = q|spinach|;

print Dumper $d;

