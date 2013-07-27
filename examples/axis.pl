#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;
use Test::More 'no_plan';

($\,$,) = ("\n",",");

my $d = [
	{ map { $_ => qq|a$_|} 0..2},
	['a'..'c'],
	{ map { $_ => qq|b$_|} 0..2},
];

my $data = Data::pQuery->data($d);
# my @queries = (
# 	q|/descendant-or-self::*[+1]|
# 	,q|/descendant::*[+1]|
# 	,q|/descendant::{*}[+1]|
# 	,q|/descendant::[*][+1]|
# 	,q|/descendant-or-self::*[+1]|
# 	,q|/descendant-or-self::{*}[+1]|
# );
# print $_, Dumper [$data->query($_)->getvalues()] foreach(@queries);
#exit;

#ok(defined $data, "data defined");
#ok($data->isa('Data::pQuery::Compiler'), "is Data::pQuery::Compiler");
verify($data, $d,'');
sub verify{
	my ($data, $d,$path) = @_;
	sub test{
		my ($data,$query, $expectedString) = @_;
		my @expected = (eval $expectedString);
		my $test = qq|$query == ($expectedString)|;
		is_deeply([$data->query($query)->getvalues()],[@expected], $test); 
	}
	my $query = qq|${path}/self::*|;
	my $expectedString = qq|\$d|;
	test($data,$query, $expectedString);
	my $query = qq|${path}/self::*[+1]|;
	my $expectedString = qq|\$d|;
	test($data,$query, $expectedString);
	my $query = qq|${path}/.|;
	my $expectedString = qq|\$d|;
	test($data,$query, $expectedString);
	my $query = qq|${path}/.[+1]|;
	my $expectedString = qq|\$d|;
	test($data,$query, $expectedString);
	if (!ref $d){
		my $query = qq|${path}/self::*[not(*)]|;
		my $expectedString = qq|\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/.[not(*)]|;
		my $expectedString = qq|\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/self::*[+1][not(*)]|;
		my $expectedString = qq|\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/.[+1][not(*)]|;
		my $expectedString = qq|\$d|;
		test($data,$query, $expectedString);
	}elsif (ref $d eq q|ARRAY|){
		my $query = qq|${path}/*|;
		my $expectedString = qq|\@\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/[*]|;
		my $expectedString = qq|\@\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/{*}|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${path}/child::*|;
		my $expectedString = qq|\@\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/child::[*]|;
		my $expectedString = qq|\@\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/child::{*}|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		foreach (0..$#$d){
			my $query = qq|${path}/$_|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/child::$_|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${path}/*[+$p]|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${path}/[*][+$p]|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${path}/{*}[+$p]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/$_/self::$_|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/$_/self::*|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/$_/self::[*]|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/$_/self::{*}|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/$_\[name() eq "$_"\]|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/*\[name() eq "$_"\]|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${path}/*\[position() == $p\]|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${path}/$_\[position() == 1\]|;
			my $expectedString = qq|\$d->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			verify($data, $d->[$_],qq|${path}/$_|);	
			my $p = $_ + 1;
			verify($data, $d->[$_],qq|${path}/*\[+$p\]|);	
			verify($data, $d->[$_],qq|${path}/[*]\[+$p\]|);	
			verify($data, $d->[$_],qq|${path}/child::*\[+$p\]|);	
			verify($data, $d->[$_],qq|${path}/child::[*]\[+$p\]|);	
			verify($data, $d->[$_],qq|${path}/self::*/$_|);	
			verify($data, $d->[$_],qq|${path}/self::[*]/$_|);	
			verify($data, $d->[$_],qq|${path}/descendant-or-self::[*][+1]/$_|);	
			verify($data, $d->[$_],qq|${path}/descendant-or-self::*[+1]/$_|);	
		}
	}elsif(ref $d eq q|HASH|){
		my $query = qq|${path}/*|;
		my $expectedString = qq|sort values \%\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/[*]|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${path}/{*}|;
		my $expectedString = qq|sort values \%\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/child::*|;
		my $expectedString = qq|sort values \%\$d|;
		test($data,$query, $expectedString);
		my $query = qq|${path}/child::[*]|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${path}/child::{*}|;
		my $expectedString = qq|sort values \%\$d|;
		test($data,$query, $expectedString);
		foreach (keys %$d){
			my $query = qq|${path}/$_|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %$d){
			my $query = qq|${path}/child::$_|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %$d){
			my $query = qq|${path}/*[+$p]|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
			$p++;
		}
		my $p = 1;
		foreach (sort keys %$d){
			my $query = qq|${path}/{*}[+$p]|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
			$p++;
		}
		my $p = 1;
		foreach (sort keys %$d){
			my $query = qq|${path}/[*][+$p]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
			$p++;
		}
		foreach (keys %$d){
			my $query = qq|${path}/$_/self::$_|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %$d){
			my $query = qq|${path}/$_/self::*|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %$d){
			my $query = qq|${path}/$_/self::{*}|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %$d){
			my $query = qq|${path}/$_/self::[*]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (keys %$d){
			my $query = qq|${path}/$_\[name() eq "$_"\]|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %$d){
			my $query = qq|${path}/*\[name() eq "$_"\]|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %$d){
			my $query = qq|${path}/*\[position() == $p\]|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
			$p++;
		}
		foreach (keys %$d){
			my $query = qq|${path}/$_\[position() == 1\]|;
			my $expectedString = qq|\$d->{$_}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %$d){
			verify($data, $d->{$_},qq|${path}/$_|);	
		 	verify($data, $d->{$_},qq|${path}/*\[+$p\]|);	
		 	verify($data, $d->{$_},qq|${path}/{*}\[+$p\]|);	
			verify($data, $d->{$_},qq|${path}/child::*\[+$p\]|);	
		 	verify($data, $d->{$_},qq|${path}/child::{*}\[+$p\]|);	
		 # 	verify($data, $d->{$_},qq|${path}/self::*/$_|);	
			# verify($data, $d->{$_},qq|${path}/self::{*}/$_|);	
		 # 	verify($data, $d->{$_},qq|${path}/descendant-or-self::{*}[+1]/$_|);	
		 # 	verify($data, $d->{$_},qq|${path}/descendant-or-self::*[+1]/$_|);	
		 	$p++;
		}
	}
}

