#!/usr/bin/perl
use strict;
use Data::xPathLike;
use Data::Dumper;
use warnings;
($\,$,) = ("\n",",");

my $data = Data::xPathLike->data([
        {invoice => {
                        Amount => 100,
                        Tax => 0.2,
                        Total => 120
                },
								itens => [qw|water soda|]       
        },
        {invoice => {
                        Amount => 200,
                        Tax => 0.15,
                        Total => 240
                },
					itens => [qw|water wine bear|]       
        },
        receipt =>{ 
        }
]);

print Dumper $data->query(q$
       //invoice[Total != Amount * (1 + Tax)]
$)->getvalues();

print $data->query(q|/0/invoice/Total|)->getvalues();
print $data->query(q|/2|)->getvalues();
print $data->query(q|//*/invoice[Total>100]/Total|)->getvalues();
print $data->query(q|//Tax|)->getvalues();
print $data->query(q|//Total[../Tax = .2]|)->getvalues();
print Dumper $data->query(q|//*[count(itens/*) > 1][1]|)->getvalues();
print $data->query(q|sum(//Total)|)->getvalues();

exit;
