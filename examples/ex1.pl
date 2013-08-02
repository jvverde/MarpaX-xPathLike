#!/usr/bin/perl
use strict;
use MarpaX::xPathLike;
use Data::Dumper;
use warnings;
($\,$,) = ("\n",",");

use strict;
use MarpaX::xPathLike;
use Data::Dumper;

($\,$,) = ("\n",",");
my $d = {
        drinks => {
                q|Alcoholic beverage| => 'not allowed',
                q|Soft drinks| => [qw|Soda Coke|]
        },
        food => { 
                fruit => [qw|bananas apples oranges pears|], 
                vegetables  => [qw|potatoes  carrots tomatoes|]
        } 
};

my $data = MarpaX::xPathLike->data($d);
my $results = $data->query(q|/*/*/0|);
my @values = $results->getvalues();
print @values;                                  
#Soda,bananas,potatoes

my $ref = $results->getref();
$$ref = 'Tonic';
print $d->{drinks}->{q|Soft drinks|}->[0];      
#Tonic