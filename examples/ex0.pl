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

=pod

#print $data->query(q|/*/*[isScalar()][count(s) == 3][name() eq 'nome']|)->getvalues();
#print $data->query(q|/*/*/78|)->getvalues();
#print $data->query(q|/*/*/*|)->getvalues();
#print 'values', $data->query(q|/*/*/*|)->getvalues();
#print $data->query(q|lasts(/*/*/*)|)->getvalues();
#print $data->query(q|/*[name() ~ "oo"]/*/*|)->getvalues();
print $data->query(q|/*[+2]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/food[+2]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/food[+1]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/food[+1]/*/./*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/food[+1]/./*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/./food[+1]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/.[drinks]/food[+1]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|.[drinks]/food[+1]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/.[+1]/food[+1]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/food/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/food/*/..[+1]/*/*[value() ~ "o"][0..]|)->getvalues();
print $data->query(q|/*[+2]/*/..[+1]/*/*|)->getvalues();
print $data->query(q|/*/*/..[+1]/*/*|)->getvalues();
print Dumper $data->query(q|/..|)->getvalues();
print $data->query(q|/*/*/parent::*[+1]/*/*|)->getvalues();
print $data->query(q|/*/*/parent::*/*/*|)->getvalues();
print $data->query(q|/*/*/parent::food/*/*|)->getvalues();
print $data->query(q|/*/*/0|)->getvalues();
print $data->query(q|/*/*/[0]|)->getvalues();
print Dumper [$data->query(q|/*/*/[0]/..|)->getvalues()];
print Dumper [$data->query(q|/*/fruit/0/ancestor::*|)->getvalues()];
print Dumper [$data->query(q|/*/fruit/0/ancestor::*[+2]|)->getvalues()];
print Dumper [$data->query(q|/*/fruit/0/ancestor::*[isHash()]|)->getvalues()];
print Dumper [$data->query(q|/*/fruit/0/ancestor::*[isHash()][+2]|)->getvalues()];
print Dumper [$data->query(q|/food/*/0/ancestor::*[+2]|)->getvalues()];
print Dumper [$data->query(q|/*/*/0/ancestor::food|)->getvalues()];
print $data->query(q|//*[not(*)][last()]|)->getvalues();
print $data->query(q|//*[last()][parent::fruit]|)->getvalues();
print Dumper [$data->query(q|//*[last()][parent::fruit]/ancestor::*|)->getvalues()];
print Dumper [$data->query(q|//*[last()][parent::fruit]/ancestor-or-self::*|)->getvalues()];
print Dumper [$data->query(q|//*[last()][parent::fruit]/ancestor-or-self::fruit|)->getvalues()];

=cut

my $d = Data::pQuery->data({
	a => [
		{
			a => {
							a=> 'a0aa',
							b=> 'a0ab'
						},
			b =>{
						0 => 'zero',
						a=> 'a0ba',
						b=> 'a0bb',
						c=>[
								0,
								1,
								2,
						]
			}
		},
		{
			a => 'a0a',
			b => 'a0b'
		}
	],
	b => 'b'
});

print $d->query(q|/a//b/descendant::[0]|)->getvalues();
print $d->query(q|/a//b/descendant::{0}|)->getvalues();
print $d->query(q|/a//b/descendant::0|)->getvalues();
print $d->query(q|/a//b/descendant::*[not(*)]|)->getvalues();
print $d->query(q|/a//b/descendant::*[not(*)][+1]|)->getvalues();
print $d->query(q|/a//b/descendant::*[not(*)][+2]|)->getvalues();
print $d->query(q|/a//b/descendant::*[not(*)][2 == position()]|)->getvalues();
print $d->query(q|//0//*/preceding-sibling::0|)->getvalues();
print $d->query(q|//0//*/preceding-sibling::9|)->getvalues();
print $d->query(q|//0//*/following-sibling::0|)->getvalues();
print $d->query(q|//0//*/following-sibling::1|)->getvalues();
print $d->query(q|//0//*/following-sibling::2|)->getvalues();
print $d->query(q|//c/*/following-sibling::*|)->getvalues();
print $d->query(q|//c/*/preceding-sibling::*|)->getvalues();
exit;

print Dumper [$d->query(q|//b|)->getvalues()];
print Dumper [$d->query(q|/a//b|)->getvalues()];
print Dumper [$d->query(q|/a/0/b//b|)->getvalues()];
print Dumper [$d->query(q|/a/0/*//b|)->getvalues()];
print $d->query(q|/a//*[not(*)]|)->getvalues();
print $d->query(q|/a/descendent::*[not(*)]|)->getvalues();
print Dumper [$d->query(q|/a//*|)->getvalues()];
print Dumper [$d->query(q|/a/descendent::*|)->getvalues()];
print Dumper [$d->query(q|/a/descendent::0|)->getvalues()];
print Dumper [$d->query(q|/a/descendent::[0]|)->getvalues()];
exit;

my $results = $data->query(q|/*/*/[0]|);
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
print $data->query(q|/drinks/'Soft drinks'/[1]|)->getvalues();
#Coke
print '___________', $data->query(q|/drinks/'Soft drinks'/1|)->getvalues();

#the .. sequence indexes all array positions
print $data->query(q|/*/*/[..]|)->getvalues();
#Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

#the leading slash is optional
print $data->query(q|*/*/[..]|)->getvalues(); 
#Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

#negative values indexes the arrays in reverse order. -1 is the last index
print $data->query(q|/*/*/[-1]|)->getvalues();
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
print $data->query(q|/*/*[name() ~ "drinks"]/[..]|)->getvalues();
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
	/[-1..0]
|)->getvalues();
#tomatoes,carrots,potatoes

#the same as above but using a logical operation instead of two filters
print $data->query(q|
	//*[value([-1]) gt value([0]) 
		and count([..]) < 4
	]/[-1..0]
|)->getvalues();
#tomatoes,carrots,potatoes

#a query could be a function instead of a path
print $data->query(q|names(/*/*)|)->getvalues();
#Alcoholic beverage,Soft drinks,fruit,vegetables

#the function 'names' returns the keys names or indexes
print $data->query(q|names(//**)|)->getvalues();
#drinks,Alcoholic beverage,Soft drinks,0,1,food,fruit,0,1,2,3,vegetables,0,1,2

#same as above as the dot (.) means the struct itself
print $data->query(q|names(//**/.)|)->getvalues();
#drinks,Alcoholic beverage,Soft drinks,0,1,food,fruit,0,1,2,3,vegetables,0,1,2

#agian the same as above!!!
print $data->query(q|names(.//**/.)|)->getvalues();
#drinks,Alcoholic beverage,Soft drinks,0,1,food,fruit,0,1,2,3,vegetables,0,1,2

print $data->query(q|names(./*)|)->getvalues();
#drinks,food

print $data->query(q|names(//**/..)|)->getvalues();
#/,/,drinks,drinks,Soft drinks,Soft drinks,food,food,fruit,fruit,fruit,fruit,vegetables,vegetables,vegetables

#support parent axis
print $data->query(q|count(//**/parent::fruit)|)->getvalues();
#1

print $data->query(q|names(/food/fruit[3]/ancestor::*)|)->getvalues();
#/,food,fruit
print '-------------------------------------';
my $d2 = {
	drinks => [
		{q|Alcoholic beverage| => 'not allowed'},
		{q|Soft drinks| => [qw|Soda Coke|]}
	],
	food => [ 
		[qw|bananas apples oranges pears|], 
		[qw|potatoes  carrots tomatoes|]
	] 
};
my $data2 = Data::pQuery->data($d2);

#same as above as the dot (.) means the struct itself
print $data2->query(q|count(//**/parent::food)|)->getvalues();
#4
print $data2->query(q{names(//**[value() ~ "toma|oda"]/ancestor::*)})->getvalues();
print $data2->query(q{names(//**[value() ~ "toma|oda"])})->getvalues();

print $data2->query(q{names(//**/ancestor::food)})->getvalues();
print $data2->query(q{names(//**/ancestor::[0])})->getvalues();
print Dumper $data2->query(q{//**/parent::[0]})->getvalues();
print $data2->query(q{name(/.)})->getvalues();
print $data2->query(q{name(.)})->getvalues();
print $data2->query(q{/food[1][1]})->getvalues();
print Dumper $data2->query(q{/food[1][1]/parent::[1]})->getvalues();
print $data2->query(q{/drinks[1]/*[1]})->getvalues();
print Dumper $data2->query(q{/drinks[1]/*[1]/parent::'Soft drinks'})->getvalues();
print Dumper $data2->query(q{/*[1]})->getvalues(); #devia devolver o elemento da chave drinks (a que surge na primeira posição)
