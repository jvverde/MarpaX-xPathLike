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
	{invoice => {
			Amount => 200,
			Tax => 0.15,
			Total => 240
		}
	},
	receipt =>{
	}
]);

print Dumper $data->query(q$
	//invoice[value(Total) != value(Amount) * (1 + value(Tax))]
$)->getvalues();

