#!/usr/bin/perl
use strict;
use utf8;
use Data::pQuery;
use Data::Dumper;
use Test::More 'no_plan';
use Devel::Cycle;
use Test::LeakTrace;

($\,$,) = ("\n",",");

my $d = [
	{ map { $_ => qq|a$_|} 0..2},
	['a'..'b', {
				q|two words key| => [qw|Σ Φ Ψ Ω Δ|], 
				q|!$%#&/()=?[]'"| => q|some text|
			},
			[{q|Σ| => q|sigma|, q|Ψ| => q|psi|}, [], [[[[[[[{q|λμνρ| => 'others'}]]]]]]]]
	],
	{ map { $_ => qq|b$_|} 0..3},
];

my $data = Data::pQuery->data($d);

#ok(defined $data, "data defined");
#ok($data->isa('Data::pQuery::Compiler'), "is Data::pQuery::Compiler");
my $x={};
verify($data, undef,'','$d');
sub escape{
	my $s = $_[0];
	$s =~ s/[\N{U+21}-\N{U+2F}\N{U+3A}-\N{U+40}\N{U+5B}-\N{U+60}\N{U+7B}-\N{U+7E}]/\\$&/g;
	return $s;
}
sub verify{
	my ($data, undef,$xpath, $path) = @_;
	sub test{
		my ($data,$query, $expectedString) = @_;
		#print "expectedString -> $expectedString";
		my @expected = (eval $expectedString);
		#print Dumper \@expected;
		my $test = qq|$query == ($expectedString)|;
		#print "test -> $test";
		my @r = $data->query($query)->getvalues();
		is_deeply([@r],[@expected], $test); 
	}
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
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/child::$_|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/*[+$p]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/[*][+$p]|;
			my $expectedString = $path.qq|->[$_]|;
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
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/self::*|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/self::[*]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/self::{*}|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_\[name() eq "$_"\]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/*\[name() eq "$_"\]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/*\[position() == $p\]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_\[position() == 1\]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/preceding-sibling::*|;
			my $f = $_-1;
			my $expectedString = qq|\@{$path}[0..$f]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/preceding-sibling::*[+1]|;
			my $f = $_ - 1;
			my $expectedString = $_ > 0 ? $path.qq|->[$f]| : q||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/preceding-sibling::*[last()]|;
			my $f = $_ - 1;
			my $expectedString = $_ > 0 ? $path.qq|->[0]| : q||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/following-sibling::*|;
			my $i = $_+1;
			my $expectedString = qq|\@{$path}[$i..$#$d]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/following-sibling::*[+1]|;
			my $i = $_+1;
			my $expectedString =  $_ < $#$d ? $path.qq|->[$i]| : q||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/following-sibling::*[last()]|;
			my $i = $_+1;
			my $expectedString =  $_ < $#$d ? $path.qq|->[$#$d]| : q||;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/parent::*|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/..|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/ancestor::*[+1]|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $query = qq|${xpath}/$_/ancestor-or-self::*[position() < 3]|;
			my $expectedString =  qq|($path, $path\->[$_])|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			verify($data, $d->[$_],qq|${xpath}/$_|,$path.qq|->[$_]|);	
			my $p = $_ + 1;
			verify($data, $d->[$_],qq|${xpath}/*\[+$p\]|,$path.qq|->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/[*]\[+$p\]|,$path.qq|->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/child::*\[+$p\]|,$path.qq|->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/child::[*]\[+$p\]|,$path.qq|->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/self::*/$_|,$path.qq|->[$_]|);	
		}
	}elsif(ref $d eq q|HASH|){
		my $query = qq|${xpath}/*|;
		my $expectedString = sprintf('map {%1$s->{$_}} sort keys %{%1$s}',$path);
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/[*]|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/{*}|;
		my $expectedString = sprintf('map {%1$s->{$_}} sort keys %{%1$s}',$path);
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::*|;
		my $expectedString = sprintf('map {%1$s->{$_}} sort keys %{%1$s}',$path);
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::[*]|;
		my $expectedString = qq||;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/child::{*}|;
		my $expectedString = sprintf('map {%1$s->{$_}} sort keys %{%1$s}',$path);
		test($data,$query, $expectedString);
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/child::{$_}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/*[+$p]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
			$p++;
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/{*}[+$p]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
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
			my $query = qq|${xpath}/{$_}/self::{$_}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}/self::*|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}/self::{*}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}/self::[*]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $v = $_;
			$v =~ s/"/\\"/g;
			my $query = qq|${xpath}/{$_}[name() eq "$v"]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $v = $_;
			$v =~ s/"/\\"/g;
			my $query = qq|${xpath}/*[name() eq "$v"]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/*\[position() == $p\]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
			$p++;
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}\[position() == 1\]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $query = qq|${xpath}/{$keys[$_]}/preceding-sibling::*|;
			my $expectedString = $_ > 0 ? 
				sprintf('@{%1$s}{%2$s}',$path, join(
					',', 
					map {qq|qq/$_/|} 
					map {escape($_)} 
					@keys[0..$_-1]
				)) 
				: q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $query = qq|${xpath}/{$keys[$_]}/preceding-sibling::*[+1]|;
			my $expectedString =  $_ > 0 ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[$_-1])) : q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $query = qq|${xpath}/{$keys[$_]}/preceding-sibling::*[last()]|;
			my $expectedString =  $_ > 0 ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[0])) : q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $query = qq|${xpath}/{$keys[$_]}/following-sibling::*|;
			my $expectedString = $_ < $#keys ? qq|\@{$path}{|
				.join(
					',', 
					map {qq|qq/$_/|} 
					map {escape($_)} 
					@keys[$_+1..$#keys]
				).q|}| : q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $query = qq|${xpath}/{$keys[$_]}/following-sibling::*[+1]|;
			my $expectedString =  $_ < $#keys ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[$_+1])) : q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $query = qq|${xpath}/{$keys[$_]}/following-sibling::*[last()]|;
			my $expectedString =  $_ < $#keys ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[$#keys])) : q||;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}/parent::*|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}/..|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}/ancestor::*[+1]|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $query = qq|${xpath}/{$_}/ancestor-or-self::*[position() < 3]|;
			my $k = escape($_);
			my $expectedString =  qq|($path, $path\->{qq/$k/})|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $k = escape($_);
			verify($data, $d->{$_},qq|${xpath}/{$_}|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/*\[+$p\]|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/{*}\[+$p\]|,$path.qq|->{qq/$k/}|);	
			verify($data, $d->{$_},qq|${xpath}/child::*\[+$p\]|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/child::{*}\[+$p\]|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/self::*/{$_}|,$path.qq|->{qq/$k/}|);	
		 	$p++;
		}
	}
}

