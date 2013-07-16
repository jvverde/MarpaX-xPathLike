#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = (qq|\n|, q|,|);
my $data = Data::pQuery->data([
	{invoice => {
			Amount => 100,
			Tax => 0.2,
			Total => 120
		}
	},
	invoice => {
			Amount => 200,
			Tax => 0.2,
			Total => 220
	},
	receipt =>{
	}
]);

#print $data->query(q!**{count([..]|*|a) == 3}[0]!)->getvalues();
print Dumper $data->query(q$
	[..]//Tax
$)->getvalues();
#	//Tax | /**/Tax | /Tax | Tax | /**[3] | [3]

