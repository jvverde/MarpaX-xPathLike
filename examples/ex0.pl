#!/usr/bin/perl
use strict;
use Data::pQuery;
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

my $data = Data::pQuery->data($d);
my $results = $data->query(q|/*/*[0]|);
my @values = $results->getvalues();
print @values;					
#Soda,bananas,potatoes

my $ref = $results->getref();
$$ref = 'Tonic';
print $d->{drinks}->{q|Soft drinks|}->[0];	
#Tonic

#keys with spaces or especial characters should be delimited 
#by double quotes 
print $data->query(q|/drinks/"Alcoholic beverage"|)->getvalues();
#not allowed

#or by single quotes
print $data->query(q|/drinks/'Soft drinks'[1]|)->getvalues();
#Coke

#the .. sequence indexes all array positions
print $data->query(q|/*/*[..]|)->getvalues();
#Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

#the leading slash is optional
print $data->query(q|*/*[..]|)->getvalues(); 
#Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

#negative values indexes the arrays in reverse order. -1 is the last index
print $data->query(q|/*/*[-1]|)->getvalues();
#Coke,pears,tomatoes

#Square brackets are also used to specify filters
print $data->query(q|/*/*[isScalar()]|)->getvalues();
#not allowed

#Like xpath a variable path length is defined by the sequence //
print $data->query(q|//*[isScalar()]|)->getvalues();
#not allowed

#The step ** select any key or any index, while the step * only select any key
print $data->query(q|//**[isScalar()]|)->getvalues();
#not allowed,Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

#the filter could be a match between a string expression and a pattern
print $data->query(q|/*/*[name() ~ "drinks"][..]|)->getvalues();
#Tonic,Coke

#the same as above (in this particular data-strucure)
print $data->query(q|/*/*[name() ~ "drinks"]/**|)->getvalues();
#Tonic,Coke


#The returned values does not need to be scalars
print Dumper $data->query(q|/*/vegetables|)->getvalues();
=pod
$VAR1 = [
          'potatoes',
          'carrots',
          'tomatoes'
        ];
=cut

#using two filters in sequence 
print $data->query(q|
	//*
	[value([-1]) gt value([0])]
	[count([..]) < 4]
	[-1..0]
|)->getvalues();
#tomatoes,carrots,potatoes

#the same as above but using a logical operation instead of two filters
print $data->query(q|
	//*[value([-1]) gt value([0]) 
		and count([..]) < 4
	][-1..0]
|)->getvalues();
#tomatoes,carrots,potatoes

#a query could be a function instead of a path
print $data->query(q|names(/*/*)|)->getvalues();
#Alcoholic beverage,Soft drinks,fruit,vegetables

#the function 'names' returns the keys names or indexes
print $data->query(q|names(//**)|)->getvalues();
#drinks,Alcoholic beverage,Soft drinks,0,1,food,fruit,0,1,2,3,vegetables,0,1,2

print $data->query(q|names(//**/..)|)->getvalues();
#,,drinks,drinks,Soft drinks,Soft drinks,food,food,fruit,fruit,fruit,fruit,vegetables,vegetables,vegetables

