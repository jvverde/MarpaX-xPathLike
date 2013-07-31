#!/usr/bin/perl
use strict;
use Data::xPathLike;
use Data::Dumper;
use warnings;
($\,$,) = ("\n",",");

my $data = Data::xPathLike->data({
       food => {
               fruit => 'bananas',
               vegetables => 'unions'
       },
       drinks => {
               wine => 'Porto',
               water => 'Evian'
       }
});


my @values1 = $data->query('/*/*')->getvalues();
print @values1; # Evian,Porto,bananas,unions

my @values2 = $data->query('/*/wine')->getvalues();
print @values2; #Porto

#using a predicate, to get only first level entry which contains a fruit key
my @values3 = $data->query('/*[fruit]/*')->getvalues();
print @values3; #bananas,unions
#using another filter to return only elements which have the value matching 
#a /an/ pattern
my @values4 = $data->query('/*/*[. ~ "an"]')->getvalues();
print @values4;# Evian,bananas

my @values5 = $data->query('//*[isScalar()]')->getvalues();
print @values5;#Evian,Porto,bananas,unions