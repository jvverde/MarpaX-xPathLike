#!/usr/bin/perl
use strict;
use utf8;
use Data::xPathLike;
use Data::Dumper;
use Test::More 'no_plan';
use Devel::Cycle;
use Test::LeakTrace;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

($\,$,) = ("\n",",");

my $prob = shift;
$prob ||= 1;

my $d = [
	(map {{$_ => $_}} split //, q|!$%#&<>-_.:,;^~'`\\@£§\/][)(}{(){}=?[]'"|),
	#{ map { $_ => qq|_$_|} map {chr($_)} 200..300},
	# { map { 'a'.$_ => qq|_$_|} 'Φ'..'Δ'},
	# { map { $_.'"' => qq|_$_|} 'Φ'..'Δ'},
	# { map { '"'.$_ => qq|_$_|} 'Φ'..'Δ'},
	# { map { "'".$_ => qq|_$_|} 'Φ'..'Δ'},
	{ map { $_ => qq|a$_|} 0..2},
	['a'..'b', {
				q|two words key| => [qw|Σ Φ Ψ Ω Δ|], 
				q|!$%#&<>-_.:,;^~'`\\@£§/][)(}{(){}=?[]'"| => q|some text|,
			},
			[{Σ => q|sigma|, Ψ => q|psi|, others => [qw|ω τ ξ|]}, [{λμνρ => 'others'}]]
	],
	{ map { $_ => qq|b$_|} 0..3},
];
#print Dumper $d;

my $data = Data::xPathLike->data($d);
# print Dumper $data->query(q|/17/{"\\"}/self::{"\\"}|)->getvalues();
# exit;
# print Dumper $data->query('/6/3/0')->getvalues();
# exit;


#ok(defined $data, "data defined");
#ok($data->isa('Data::xPathLike::Compiler'), "is Data::xPathLike::Compiler");
my $x={};
verify($data, undef,'','$d');
sub escape{
	my $s = $_[0];
	$s =~ s/[\N{U+21}-\N{U+2F}\N{U+3A}-\N{U+40}\N{U+5B}-\N{U+60}\N{U+7B}-\N{U+7E}]/\\$&/g;
	return $s;
}
sub step{
	my $s = $_[0];
	return (rand(100) > 50 ? $s : (rand(100) > 50 ? qq|"$s"| : qq|'$s'|)) if $s =~ /^\d+$/;
	return (rand(100) > 50 ? $s : (rand(100) > 50 ? qq|"$s"| : qq|'$s'|)) if $s =~ /^[^\d:.\/*,'"|\s\]\[\(\)\{\}\\+-<>=!]+$/i;
	$s =~ s/"|\\/\\$&/g;
	return qq|"$s"|;
}
sub verify{
	my ($data, undef,$xpath, $path) = @_;
	sub test{
		return if rand(100) > $prob;
		my ($data,$query, $expectedString) = @_;
		#print "expectedString -> $expectedString";
		my @expected = (eval $expectedString);
		#print Dumper \@expected;
		my $test = qq|$query == ($expectedString)|;
		#print "test -> $test";
		my @r = eval {$data->query($query)->getvalues()};
		is_deeply([@r],[@expected], $test); 
	}
	my $d = eval $path;
	my $query = qq|${xpath}/self::*|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	my $query = qq|${xpath}/self::*[1]|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	my $query = qq|${xpath}/.|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	my $query = qq|${xpath}/.[1]|;
	my $expectedString = qq|$path|;
	test($data,$query, $expectedString);
	if (!ref $d){
		my $query = qq|${xpath}/self::*[not(*)]|;
		my $expectedString = qq|$path|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/.[not(*)]|;
		my $expectedString = qq|$path|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/self::*[1][not(*)]|;
		my $expectedString = qq|$path|;
		test($data,$query, $expectedString);
		my $query = qq|${xpath}/.[1][not(*)]|;
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
			my $query = qq|${xpath}/*[$p]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/[*][$p]|;
			my $expectedString = $path.qq|->[$_]|;
			test($data,$query, $expectedString);
		}
		foreach (0..$#$d){
			my $p = $_+1;
			my $query = qq|${xpath}/{*}[$p]|;
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
			my $query = qq|${xpath}/$_/preceding-sibling::*[1]|;
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
			my $query = qq|${xpath}/$_/following-sibling::*[1]|;
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
			my $query = qq|${xpath}/$_/ancestor::*[1]|;
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
			verify($data, $d->[$_],qq|${xpath}/*\[$p\]|,$path.qq|->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/[*]\[$p\]|,$path.qq|->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/child::*\[$p\]|,$path.qq|->[$_]|);	
			verify($data, $d->[$_],qq|${xpath}/child::[*]\[$p\]|,$path.qq|->[$_]|);	
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
			my $s = step($_);
			my $query = qq|${xpath}/{$s}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/child::{$s}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/*[$p]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
			$p++;
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/{*}[$p]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
			$p++;
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $query = qq|${xpath}/[*][$p]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
			$p++;
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/self::{$s}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/self::*|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/self::{*}|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/self::[*]|;
			my $expectedString = qq||;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $v = $_;
			$v =~ s/"/\\"/g;
			my $s = step($_);
			my $query = qq|${xpath}/{$s}[name() eq "$v"]|;
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
			my $s = step($_);
			my $query = qq|${xpath}/{$s}\[position() == 1\]|;
			my $k = escape($_);
			my $expectedString = $path.qq|->{qq/$k/}|;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $s = step($keys[$_]);
			my $query = qq|${xpath}/{$s}/preceding-sibling::*|;
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
			my $s = step($keys[$_]);
			my $query = qq|${xpath}/{$s}/preceding-sibling::*[1]|;
			my $expectedString =  $_ > 0 ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[$_-1])) : q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $s = step($keys[$_]);
			my $query = qq|${xpath}/{$s}/preceding-sibling::*[last()]|;
			my $expectedString =  $_ > 0 ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[0])) : q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $s = step($keys[$_]);
			my $query = qq|${xpath}/{$s}/following-sibling::*|;
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
			my $s = step($keys[$_]);
			my $query = qq|${xpath}/{$s}/following-sibling::*[1]|;
			my $expectedString =  $_ < $#keys ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[$_+1])) : q||;
			test($data,$query, $expectedString);
		}
		my @keys = sort keys %{$d};
		foreach (0..$#keys){
			my $s = step($keys[$_]);
			my $query = qq|${xpath}/{$s}/following-sibling::*[last()]|;
			my $expectedString =  $_ < $#keys ? sprintf('%1$s->{qq/%2$s/}', $path, escape($keys[$#keys])) : q||;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/parent::*|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/..|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/ancestor::*[1]|;
			my $expectedString =  $path;
			test($data,$query, $expectedString);
		}
		foreach (keys %{$d}){
			my $s = step($_);
			my $query = qq|${xpath}/{$s}/ancestor-or-self::*[position() < 3]|;
			my $k = escape($_);
			my $expectedString =  qq|($path, $path\->{qq/$k/})|;
			test($data,$query, $expectedString);
		}
		my $p = 1;
		foreach (sort keys %{$d}){
			my $k = escape($_);
			my $s = step($_);
			verify($data, $d->{$_},qq|${xpath}/{$s}|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/*\[$p\]|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/{*}\[$p\]|,$path.qq|->{qq/$k/}|);	
			verify($data, $d->{$_},qq|${xpath}/child::*\[$p\]|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/child::{*}\[$p\]|,$path.qq|->{qq/$k/}|);	
		 	verify($data, $d->{$_},qq|${xpath}/self::*/{$s}|,$path.qq|->{qq/$k/}|);	
		 	$p++;
		}
	}
}

