#!/usr/bin/perl
use strict;
use Data::xPathLike;
use Data::Dumper;
use warnings;
($\,$,) = ("\n",",");

use strict;
use Data::xPathLike;
use Data::Dumper;

($\,$,) = ("\n",",");


my $query = Data::xPathLike->compile('*');                #compile the query

my @values1 = $query->data({fruit => 'bananas'})->getvalues();
print @values1;
# @values1 = (bananas)

my @values2 = $query->data({
  fruit => 'bananas', 
  vegetables => 'orions'
})->getvalues();
print @values2;
# @values2 = (bananas, orions)

my @values3 = $query->data({
  food => {fruit => 'bananas'}
})->getvalues();
print Dumper @values3;
# @values3 = ({fruit => 'bananas'})