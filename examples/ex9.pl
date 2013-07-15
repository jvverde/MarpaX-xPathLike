#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;
$Data::Dumper::Deepcopy = 1;
($\,$,) = (qq|\n|, q|,|);
my $data = Data::pQuery->data({
	d => {
		x => 6,
		y => {
			z => 9
		},
		w => {}
	}
});

#print $data->query(q!/d/w/../y/z!)->getvalues();
#print $data->query(q!/d/w/..{name() eq 'd'}/y/z!)->getvalues();
#print $data->query(q!/d/*{name() eq 'w'}/../y/z!)->getvalues();
print $data->query(q!/**/../y/z!)->getvalues();

