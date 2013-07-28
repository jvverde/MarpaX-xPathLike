#!/usr/bin/perl
use strict;
use Data::pQuery;
use Data::Dumper;
use Test::More 'no_plan';
use Devel::Cycle;
use Test::LeakTrace;

($\,$,) = ("\n",",");

my $d = [
	{ map { $_ => qq|a$_|} 0..2},
	['a'..'c'],
	{ map { $_ => qq|b$_|} 0..3},
];

my $data = Data::pQuery->data($d);
# print $data->query(q|names(//*)|)->getvalues();
# print $data->query(q|name(//*)|)->getvalues();
# print $data->query(q|values(//*)|)->getvalues();
# print $data->query(q|value(//*)|)->getvalues();
# print $data->query(q|positions(//*)|)->getvalues();
# print $data->query(q|position(//*)|)->getvalues();
# print $data->query(q|lasts(//*)|)->getvalues();
# print $data->query(q|last(//*)|)->getvalues();
#exit;
# print $_, Dumper [$data->query(q|/descendant-or-self::*[+1]/[2]|)->getvalues()];
# print $_, Dumper [$data->query(q|/descendant-or-self::*[+1]/2/self::[*]|)->getvalues()];
# print $_, Dumper [$data->query(q|/descendant-or-self::*[+1]/2/self::*/2/.|)->getvalues()];
# print $_, Dumper [$data->query(q|/descendant-or-self::*[+1]/2/self::*/2/.[+1]|)->getvalues()];
# print $_, Dumper [$data->query(q|/descendant-or-self::*[+1]/2/self::{*}/2/.[+1]|)->getvalues()];
# exit;
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
my $x={};
verify($data, undef,'','$d');
sub verify{
	my ($data, $dx,$xpath, $path) = @_;
	sub test{
		my ($data,$query, $expectedString) = @_;
		print "expectedString=$expectedString";
		my @expected = (eval $expectedString);
		my $test = qq|$query == ($expectedString)|;
		my @r = $data->query($query)->getvalues();
		is_deeply([@r],[@expected], $test); 
	}
	print "xpath=$xpath";
	print "path=$path";
	my $d = eval $path;
	my $query = qq|${xpath}/self::*|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	my $query = qq|${xpath}/self::*[+1]|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	my $query = qq|${xpath}/.|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	my $query = qq|${xpath}/.[+1]|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	if (!ref $d){
		my $query = qq|${xpath}/self::*[not(*)]|;
		my $expectedString = qq|$path|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/.[not(*)]|;
		my $expectedString = qq|$path|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/self::*[+1][not(*)]|;
		my $expectedString = qq|$path|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/.[+1][not(*)]|;
		my $expectedString = qq|$path|;
		test($data,$query, $expectedString);
	}elsif (ref $d eq q|ARRAY|){
		my $query = qq|${xpath}/*|;
		my $expectedString = qq|\@{$path}|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/[*]|;
		my $expectedString = qq|\@{$path}|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/{*}|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::*|;
		my $expectedString = qq|\@{$path}|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::[*]|;
		my $expectedString = qq|\@{$path}|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::{*}|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/child::$_|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/*[+$p]|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/[*][+$p]|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/{*}[+$p]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/self::$_|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/self::*|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/self::[*]|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/self::{*}|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_\[name() eq "$_"\]|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/*\[name() eq "$_"\]|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/*\[position() == $p\]|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_\[position() == 1\]|;
			my $expectedString = qq|${path}\->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/preceding-sibling::*|;
			my $f = $_-1;
			my $expectedString = qq|\@{$path}[0..$f]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/following-sibling::*|;
			my $i = $_+1;
			my $expectedString = qq|\@{$path}[$i..$#$d]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			verify($data, $d->[$_],qq|${xpath}/$_|,qq|${path}\->[$_]|);	
			my $p = $_ + 1;
			verify($data, $d->[$_],qq|${xpath}/*\[+$p\]|,qq|${path}\->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/[*]\[+$p\]|,qq|${path}\->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/child::*\[+$p\]|,qq|${path}\->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/child::[*]\[+$p\]|,qq|${path}\->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/self::*/$_|,qq|${path}\->[$_]|);	
		}
	}elsif(ref $d eq q|HASH|){
		my $query = qq|${xpath}/*|;
		my $expectedString = qq|sort values \%{$path}|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/[*]|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/{*}|;
		my $expectedString = qq|sort values \%{$path}|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::*|;
		my $expectedString = qq|sort values \%{$path}|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::[*]|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::{*}|;
		my $expectedString = qq|sort values \%{$path}|;
		test($data,$query, $expectedString);
		foreach (keys %{$d}){
			my $query = qq|${xpath}/$_|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/child::$_|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/*[+$p]|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
			$p++;
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/{*}[+$p]|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
			$p++;
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/[*][+$p]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
			$p++;
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/$_/self::$_|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/$_/self::*|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/$_/self::{*}|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/$_/self::[*]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/$_\[name() eq "$_"\]|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/*\[name() eq "$_"\]|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/*\[position() == $p\]|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
			$p++;
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/$_\[position() == 1\]|;
			my $expectedString = qq|${path}\->{$_}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			verify($data, $d->{$_},qq|${xpath}/$_|,qq|${path}\->{$_}|);	
		 	verify($data, $d->{$_},qq|${xpath}/*\[+$p\]|,qq|${path}\->{$_}|);	
		 	verify($data, $d->{$_},qq|${xpath}/{*}\[+$p\]|,qq|${path}\->{$_}|);	
			verify($data, $d->{$_},qq|${xpath}/child::*\[+$p\]|,qq|${path}\->{$_}|);	
		 	verify($data, $d->{$_},qq|${xpath}/child::{*}\[+$p\]|,qq|${path}\->{$_}|);	
		 	verify($data, $d->{$_},qq|${xpath}/self::*/$_|,qq|${path}\->{$_}|);	
		 	$p++;
		}
	}
}

