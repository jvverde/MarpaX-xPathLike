#!/usr/bin/perl
use strict;
use Data::pQuery;

($\,$,) = (qq|\n|, q|,|);
my $data = {
	fruit => [qw|bananas apples oranges pears|], 
	vegetables => [qw|potatoes carrots tomatoes onions|]
};

my $process = Data::pQuery->process($data);

print $process->compile('*[2]')->getvalues(); #oranges,tomatoes
print $process->compile('*[-1]')->getvalues(); #pears,onions
print $process->compile('fruit[0,2]')->getvalues(); #bananas,oranges
print $process->compile('fruit[2...]')->getvalues(); #oranges,pears
print $process->compile('fruit[...1]')->getvalues(); #bananas,apples
print $process->compile('fruit[1..2]')->getvalues(); #apples,oranges
print $process->compile('fruit[2..1]')->getvalues(); #oranges,apples
print $process->compile('fruit[...]')->getvalues();#bananas,apples,oranges,pears
print $process->compile('fruit[1..-1]')->getvalues(); #apples,orangesears
print $process->compile('fruit[-1..1]')->getvalues(); #pears,oranges,apples

