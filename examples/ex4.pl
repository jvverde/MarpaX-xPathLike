#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
my $d = {
	food => {
		fruit => q|bananas|, 
		vegetables => [qw|potatoes  carrots|]
	},
	wine => 'Porto'
};
my $data = Data::pQuery->data($d);

my @all = $data->query('*')->getvalues(); 
print "all\t", Dumper \@all;

my @deepall = $data->query('**')->getvalues();
print "deepall\t", Dumper \@deepall;


