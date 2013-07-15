#!/usr/bin/perl
use strict;
use Data::pQuery;

($\,$,) = (qq|\n|, q|,|);
my $data = Data::pQuery->data({
	fruit => [qw|bananas apples oranges pears|], 
	vegetables => [qw|potatoes carrots tomatoes onions|]
});

print $data->query('*[2]')->getvalues();            #oranges,tomatoes
print $data->query('*[-1]')->getvalues();           #pears,onions
print $data->query('fruit[0,2]')->getvalues();      #bananas,oranges
print $data->query('fruit[2,0]')->getvalues();      #oranges,bananas
print $data->query('fruit[2..]')->getvalues();      #oranges,pears
print $data->query('fruit[..1]')->getvalues();      #bananas,apples
print $data->query('fruit[1..2]')->getvalues();     #apples,oranges
print $data->query('fruit[2..1]')->getvalues();     #oranges,apples
print $data->query('fruit[..]')->getvalues();      #bananas,apples,oranges,pears
print $data->query('fruit[1..-1]')->getvalues();    #apples,oranges,pears
print $data->query('fruit[-1..1]')->getvalues();    #pears,oranges,apples
print $data->query('fruit[-1..]')->getvalues();     #pears
print $data->query('fruit[3..9]')->getvalues();     #pears
print $data->query('fruit[-1..9]')->getvalues();    #pears
print $data->query('fruit[-1..-9]')->getvalues(); #pears,oranges,apples,bananas 
print $data->query('fruit[0,2..3]')->getvalues();   #bananas,oranges,pears 
print $data->query('fruit[..1,3..]')->getvalues();  #bananas,apples,pears 

