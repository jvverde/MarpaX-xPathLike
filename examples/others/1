#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;

($\,$,) = (qq|\n|, q|,|);
my $data = Data::pQuery->data([
	{invoice => {
			Amount => 100,
			Tax => 0.2,
			Total => 120,
			itens1 =>[
				0,1,2,3
			]
		}
	},
	{invoice => {
			Amount => 200,
			Tax => 0.3,
			Total => 220,
			itens2 =>[
				4,5,6,7
			]
		}
	},
	{Tax => 0.5},
	{receipt =>{}},
	[qw|a b c d|]
]);

#print $data->query(q!**{count([..]|*|a) == 3}[0]!)->getvalues();
print Dumper $data->query(q$
	//Tax{value() < 0.5}/..
$)->getvalues();
#	//Tax | /**/Tax | /Tax | Tax | /**[3] | [3]
#	//Tax{value() eq '0.3'}

