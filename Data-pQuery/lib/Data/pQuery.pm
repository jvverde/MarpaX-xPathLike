package Data::pQuery;
use utf8;
use open ":std", ":encoding(UTF-8)";
use 5.006;
use strict;
use Carp;
use warnings FATAL => 'all';
use Marpa::R2;
use Data::Dumper;
use Scalar::Util qw{looks_like_number};


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.02';

my $grammar = Marpa::R2::Scanless::G->new({
	#default_action => '::first',
	action_object	=> __PACKAGE__,
	source => \(<<'END_OF_SOURCE'),

:default ::= action => ::array
:start ::= Start

Start	::= OperExp															action => _do_arg1

OperExp ::=
	PathExpr 																		action => _do_path
	|Function 																	action => _do_arg1

Function ::=
	NumericFunction															action => _do_arg1
	| StringFunction 														action => _do_arg1
	| ListFunction 															action => _do_arg1

PathExpr ::=
	absolutePath																action => _do_absolutePath
	| relativePath															action => _do_relativePath
	| PathExpr '|' PathExpr											action => _do_pushArgs2array

relativePath ::=	
	stepPath 																		action => _do_arg1
	| indexPath 																action => _do_arg1

absolutePath ::=	
	'/' stepPath 																action => _do_arg2
	| indexPath 																action => _do_arg1

stepPath ::=
	step Filter absolutePath 										action => _do_stepFilterSubpath
	| step Filter 															action => _do_stepFilter
	| step absolutePath 												action => _do_stepSubpath
	| step																			action => _do_arg1

step ::= 
	keyname 																		action => _do_keyname
	| wildcard 																	action => _do_wildcard
	| dwildcard 																action => _do_dwildcard
	|	'..'																			action => _do_dotdot			

indexPath ::=
	IndexArray Filter absolutePath 							action => _do_indexFilterSubpath	
	| IndexArray Filter 												action => _do_indexFilter	
	| IndexArray absolutePath 									action => _do_indexSubpath		
	| IndexArray																action => _do_arg1	


IndexArray ::=  '[' IndexExprs ']'						action => _do_index


IndexExprs ::= IndexExpr+ 			separator => <comma>

IndexExpr ::=
	IntExpr																			action => _do_index_single
	| rangeExpr																	action => _do_arg1

rangeExpr ::= 
	IntExpr '..' IntExpr 												action => _do_index_range
	|IntExpr '..' 															action => _do_startRange
	| '..' IntExpr															action => _do_endRange
	| '..' 																			action => _do_allRange


Filter ::= 	
	'{' LogicalExpr '}' 												action => _do_filter
	| '{' LogicalExpr '}' Filter 								action => _do_mergeFilters

IntExpr ::=
  ArithmeticIntExpr														action => _do_arg1

 ArithmeticIntExpr ::=
 	INT 																				action => _do_arg1
	| IntegerFunction														action => _do_arg1
	| '(' IntExpr ')' 													action => _do_group
	|| '-' ArithmeticIntExpr 										action => _do_unaryOperator
	 | '+' ArithmeticIntExpr 										action => _do_unaryOperator
	|| ArithmeticIntExpr '*' ArithmeticIntExpr  action => _do_binaryOperation
	 | ArithmeticIntExpr '/' ArithmeticIntExpr  action => _do_binaryOperation
	 | ArithmeticIntExpr '%' ArithmeticIntExpr  action => _do_binaryOperation
	|| ArithmeticIntExpr '+' ArithmeticIntExpr  action => _do_binaryOperation
	 | ArithmeticIntExpr '-' ArithmeticIntExpr  action => _do_binaryOperation


NumericExpr ::=
  ArithmeticExpr 															action => _do_arg1

ArithmeticExpr ::=
	NUMBER 																			action => _do_arg1
	| NumericFunction														action => _do_arg1
	| '(' NumericExpr ')' 											action => _do_group
	|| '-' ArithmeticExpr 											action => _do_unaryOperator
	 | '+' ArithmeticExpr 											action => _do_unaryOperator
	|| ArithmeticExpr '*' ArithmeticExpr				action => _do_binaryOperation
	 | ArithmeticExpr '/' ArithmeticExpr				action => _do_binaryOperation
	 | ArithmeticExpr '%' ArithmeticExpr				action => _do_binaryOperation
	|| ArithmeticExpr '+' ArithmeticExpr				action => _do_binaryOperation
	 | ArithmeticExpr '-' ArithmeticExpr				action => _do_binaryOperation

LogicalExpr ::=
	compareExpr																	action => _do_arg1
	|LogicalFunction														action => _do_arg1

compareExpr ::=	
	PathExpr 																		action => _do_exists
	|| NumericExpr '<' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '<=' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '>' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '>=' NumericExpr							action => _do_binaryOperation
	 | StringExpr 'lt' StringExpr								action => _do_binaryOperation
	 | StringExpr 'le' StringExpr								action => _do_binaryOperation
	 | StringExpr 'gt' StringExpr								action => _do_binaryOperation
	 | StringExpr 'ge' StringExpr								action => _do_binaryOperation
	 | StringExpr '~' RegularExpr								action => _do_binaryOperation
	 | StringExpr '!~' RegularExpr							action => _do_binaryOperation
	 | NumericExpr '==' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '!=' NumericExpr							action => _do_binaryOperation
	 | StringExpr 'eq' StringExpr								action => _do_binaryOperation
	 | StringExpr 'ne' StringExpr								action => _do_binaryOperation
	|| compareExpr 'and' LogicalExpr						action => _do_binaryOperation
	|| compareExpr 'or' LogicalExpr							action => _do_binaryOperation

#operator match, not match, in, intersect and union are missing

StringExpr ::=
	STRING 																			action => _do_arg1
 	| StringFunction 														action => _do_arg1
 	|| StringExpr '||' StringExpr  							action => _do_binaryOperation


RegularExpr 
	::= STRING																	action => _do_re

LogicalFunction ::=
	'not' '(' LogicalExpr ')'			 							action => _do_func
	| 'isRef' '('  PathArgs  ')'			 					action => _do_func
	| 'isScalar' '(' PathArgs ')'			 					action => _do_func
	| 'isArray' '(' PathArgs ')'			 					action => _do_func
	| 'isHash' '(' PathArgs ')'			 						action => _do_func
	| 'isCode' '(' PathArgs ')'									action => _do_func

StringFunction ::=
	NameFunction																action => _do_arg1
	| ValueFunction															action => _do_arg1

NameFunction ::= 
	'name' '(' PathArgs ')'				 							action => _do_func

PathArgs ::= 
	PathExpr						  											action => _do_arg1
	|EMPTY																			action => _do_arg1

EMPTY ::=

ValueFunction ::= 
	'value' '(' PathArgs ')'				 						action => _do_func

CountFunction ::= 
	'count' '(' PathExpr ')'				 						action => _do_func

SumFunction ::= 
	'sum' '(' PathExpr ')'				 							action => _do_func

SumProductFunction ::= 
	'sumproduct' '(' PathExpr ',' PathExpr ')'	action => _do_funcw2args

NumericFunction ::=
	CountFunction																action => _do_arg1
	|ValueFunction															action => _do_arg1
	|SumFunction																action => _do_arg1
	|SumProductFunction													action => _do_arg1

IntegerFunction ::=
	CountFunction																action => _do_arg1

ListFunction ::=
	'names' '(' PathArgs ')'    		 						action => _do_func
	| 'values' '(' PathArgs ')'    		 					action => _do_func


 NUMBER ::= 
 	unumber 																		action => _do_arg1
 	| '-' unumber 															action => _do_join
 	| '+' unumber 															action => _do_join

unumber	
	~ uint
	| uint frac
	| uint exp
	| uint frac exp
 
uint            
	~ digits

digits 
	~ [\d]+
 
frac
	~ '.' digits
 
exp
	~ e digits
 
e
	~ 'e'
	| 'e+'
	| 'e-'
	| 'E'
	| 'E+'
	| 'E-'

INT ::= 
	UINT 																		action => _do_arg1
	| '+' UINT  														action => _do_join	#avoid ambiguity
	| '-' UINT  														action => _do_join	#avoid ambiguity

UINT
	~digits

STRING ::= 
	double_quoted               								action => _do_double_quoted
	| single_quoted              								action => _do_single_quoted


single_quoted        
	~ [''] single_quoted_chars ['']

single_quoted_chars      
 	~ single_quoted_char*
 
single_quoted_char  
	~ [^']
	| '\' [']

double_quoted        
	~ ["] double_quoted_chars ["]

double_quoted_chars      
 	~ double_quoted_char*
 
double_quoted_char  
	~ [^"]
	| '\' '"'

wildcard 
	~ [*]

dwildcard 
	~ [*][*]

keyname ::= 
	token																				action => _do_token
	| STRING            												action => _do_arg1

token ~ [^./*,'"|\s\]\[\(\)\{\}\\+-]+


:discard 
	~ WS

WS 
	~ [\s]+

comma 
	~ ','

END_OF_SOURCE
});


sub _do_arg1{ return $_[1]};
sub _do_arg2{ return $_[2]};

sub _do_keyname{
	my $k = $_[1];
	return {step => $k};
}
sub _do_token{
	my $arg = $_[1];
	$arg =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character
	return $arg;
}
sub _do_double_quoted {
    my $s = $_[1];
    $s =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character 
    $s =~ s/^"|"$//g;
    $s =~ s/\\"/"/g;
    return $s;
}
sub _do_single_quoted {
    my $s = $_[1];
    $s =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character 
    $s =~ s/^'|'$//g;
    $s =~ s/\\'/'/g;
    return $s;
}
sub _do_re{
	my $re = $_[1];
	return qr/$re/;
}
sub _do_func{
	my $args =	$_[3] || [];
	return {oper => [$_[1], $args]}
}
sub _do_funcw2args{
	return {oper => [$_[1], $_[3],$_[5]]}
}
sub _do_join{
	return join '', @_[1..$#_];
}
sub _do_group{
	return $_[2]
}
sub _do_unaryOperator{
	return {oper => [@_[1,2]]}
}
sub _do_binaryOperation{
	my $oper = 	[$_[2]];
	my $args = 	[@_[1,3]];
	foreach my $i (0..$#$args){
		if (ref $args->[$i] eq q|HASH| 
			and defined $args->[$i]->{q|oper|} 
			and $args->[$i]->{q|oper|}->[0] eq $oper->[0]){
			my $list = $args->[$i]->{q|oper|};
			push @$oper, @{$list}[1..$#$list];
		}else{
			push @$oper, $args->[$i]; 
		} 
	}
	return {oper => $oper};
}
sub _do_exists{
	return {oper => [q|exists|, $_[1]]}
}
sub _do_stepFilterSubpath(){
	my ($step, $filter, $subpath) = @_[1..3];
	carp q|arg is not a hash ref| unless ref $step eq q|HASH|; 
	@{$step}{qw|filter subpath|} = ($filter,$subpath);
	return $step;
}
sub _do_stepFilter(){
	my ($step, $filter) = @_[1,2];
	carp q|arg is not a hash ref| unless ref $step eq q|HASH|; 
	$step->{filter} = $filter;
	return $step;
}
sub _do_stepSubpath{
	my ($step,$subpath) = @_[1,2];
	carp q|arg is not a hash ref| unless ref $step eq q|HASH|; 
	$step->{subpath} = $subpath;
	return $step;
}
sub _do_indexFilterSubpath(){
	my ($index, $filter, $subpath) = @_[1..3];
	carp q|arg is not a hash ref| unless ref $index eq q|HASH|; 
	@{$index}{qw|filter subpath|} = ($filter,$subpath);
	return $index;
}
sub _do_indexFilter(){
	my ($index, $filter) = @_[1,2];
	carp q|arg is not a hash ref| unless ref $index eq q|HASH|; 
	$index->{filter} = $filter;
	return $index;
}
sub _do_indexSubpath{
	my ($index,$subpath) = @_[1,2];
	carp q|arg is not a hash ref| unless ref $index eq q|HASH|; 
	$index->{subpath} = $subpath;
	return $index;
}
sub _do_path{
	return {paths => $_[1]}	
}
sub _do_pushArgs2array{
	my ($a,$b) = @_[1,3];
	my @array = (@$a,@$b);
	return \@array;
}
sub _do_absolutePath{
	return [{absolute => 1, path => $_[1]}];
}
sub _do_relativePath{
	return [{relative => 1, path => $_[1]}];
}
sub _do_filter{ return [$_[2]]};
sub _do_mergeFilters{
	my ($filter, $filters) = @_[2,4];
	my @filters = ($filter, @$filters);
	return \@filters; 
}
sub _do_index{
	return {indexes => $_[2]}
}
sub _do_index_single{
	return {index => $_[1]}
}
sub _do_index_range{
	return {range => [@_[1,3]]}
}
sub _do_startRange{
	{from => $_[1]}
}
sub _do_endRange{
	{to => $_[2]}
}
sub _do_allRange{
	{all => 1}
}
sub _do_wildcard{
	my $k = $_[1];
	return {wildcard => $k};
}
sub _do_dwildcard{
	my $k = $_[1];
	return {dwildcard => $k};
}
sub _do_dotdot{
	my $k = $_[1];
	return {q|..| => $k};	
}
#############################end of rules################################

my @context = ();
my $operatorBy;
my $indexesProc;
my $keysProc;

sub _operation($){
	my $operData = $_[0];
	return undef unless defined $operData and ref $operData eq q|HASH| and exists $operData->{oper};
	my @params = @{$operData->{oper}};
	my $oper = $params[0];
	return undef unless exists $operatorBy->{$oper};
	my @args = @params[1..$#params];
	return $operatorBy->{$oper}->(@args);  
}
sub _arithmeticOper(&$$;@){
		my ($oper,$x,$y,@e) = @_;
		$x = _operation($x) if ref $x;
		$y = _operation($y) if ref $y;
		my $res = $oper->($x,$y);
		foreach my $e (@e){
			$e = _operation($e) if ref $e;
			$res = $oper->($res,$e);
		}
		return $res
}
sub _logicalOper(&$$){
		my ($oper,$x,$y) = @_;
		$x = _operation($x) if ref $x and ref $x ne q|Regexp|;
		$y = _operation($y) if ref $y and ref $y ne q|Regexp|;
		return $oper->($x,$y)
}
$operatorBy = {
	'eq' => sub($$){
		return _logicalOper(sub {$_[0] eq $_[1]}, $_[0], $_[1]);
	},
	'ne' => sub($$){
		return _logicalOper(sub {$_[0] ne $_[1]}, $_[0], $_[1]);
	},
	'==' => sub($$){
		return _logicalOper(sub {$_[0] == $_[1]}, $_[0], $_[1]);
	},
	'!=' => sub($$){
		return _logicalOper(sub {$_[0] != $_[1]}, $_[0], $_[1]);
	},
	'>' => sub($$){
		return _logicalOper(sub {$_[0] > $_[1]}, $_[0], $_[1]);
	},
	'>=' => sub($$){
		return _logicalOper(sub {$_[0] >= $_[1]}, $_[0], $_[1]);
	},
	'<' => sub($$){
		return _logicalOper(sub {$_[0] < $_[1]}, $_[0], $_[1]);
	},
	'<=' => sub($$){
		return _logicalOper(sub {$_[0] <= $_[1]}, $_[0], $_[1]);
	},
	'>=' => sub($$){
		return _logicalOper(sub {$_[0] >= $_[1]}, $_[0], $_[1]);
	},
	'lt' => sub($$){
		return _logicalOper(sub {$_[0] lt $_[1]}, $_[0], $_[1]);
	},
	'le' => sub($$){
		return _logicalOper(sub {$_[0] le $_[1]}, $_[0], $_[1]);
	},
	'gt' => sub($$){
		return _logicalOper(sub {$_[0] gt $_[1]}, $_[0], $_[1]);
	},
	'ge' => sub($$){
		return _logicalOper(sub {$_[0] ge $_[1]}, $_[0], $_[1]);
	},
	'and' => sub($$){
		return _logicalOper(sub {$_[0] and $_[1]}, $_[0], $_[1]);
	},
	'or' => sub($$){
		return _logicalOper(sub {$_[0] or $_[1]}, $_[0], $_[1]);
	},
	'~' => sub($$){
		return _logicalOper(sub {$_[0] =~ $_[1]}, $_[0], $_[1]);
	},
	'!~' => sub($$){
		return _logicalOper(sub {$_[0] !~ $_[1]}, $_[0], $_[1]);
	},
	'+' => sub($$;@){
		return _arithmeticOper(sub {$_[0] + $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'*' => sub($$;@){
		return _arithmeticOper(sub {$_[0] * $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'/' => sub($$;@){
		return _arithmeticOper(sub {$_[0] / $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'-' => sub($$;@){
		return _arithmeticOper(sub {$_[0] - $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'%' => sub($$;@){
		return _arithmeticOper(sub {$_[0] % $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	names => sub{
		return map {$_->{name}} _getSubObjectsOrCurrent(@_);
	},
	name => sub{
		my @r = $operatorBy->{names}->(@_);
		return $r[0] if defined $r[0];
		return q||; 
	},
	values => sub{
		return map {${$_->{data}}} _getSubObjectsOrCurrent(@_);
	},
	value => sub(){
		my @r = $operatorBy->{values}->(@_);
		return $r[0] if defined $r[0];
		return q||; 
	},
	isHash => sub{
		my @r = grep {ref ${$_->{data}} eq q|HASH|} _getSubObjectsOrCurrent(@_);
		return @r > 0;
	},
	isArray => sub{
		my @r = grep {ref ${$_->{data}} eq q|ARRAY|} _getSubObjectsOrCurrent(@_);
		return @r > 0;	
	},
	isCode => sub{
		my @r = grep {ref ${$_->{data}} eq q|CODE|} _getSubObjectsOrCurrent(@_);
		return @r > 0;				
	},
	isRef => sub{
		my @r = grep {ref ${$_->{data}}} _getSubObjectsOrCurrent(@_);
		return @r > 0;	
	},
	isScalar => sub{
		my @r = grep {!ref ${$_->{data}}} _getSubObjectsOrCurrent(@_);
		return @r > 0;		
	},
	count =>sub{
		my @r = _getSubObjectsOrCurrent(@_);
		return scalar @r;
	},
	exists => sub{
		my @r = _getSubObjectsOrCurrent(@_);
		return scalar @r > 0;		
	},
	not => sub{
		return !_operation($_[0]);
	},
	sum => sub{
		my @r = _getSubObjectsOrCurrent($_[0]);
		my @s = grep{ref $_->{data} eq q|SCALAR| and looks_like_number(${$_->{data}})} @r; #ignore entry if it is not a scalar
		my $s = 0;
		$s += ${$_->{data}} foreach (@s);
		return $s;	
	},
	sumproduct => sub{
		my @r = _getSubObjectsOrCurrent($_[0]);
		my @s = _getSubObjectsOrCurrent($_[1]);
		my $size = $#r < $#s ? $#r: $#s;
		my $s = 0;
		foreach (0..$size){
			$s += ${$r[$_]->{data}} * ${$s[$_]->{data}} 
				if ref $r[$_]->{data} eq q|SCALAR| 
				and ref $s[$_]->{data} eq q|SCALAR|
				and looks_like_number(${$r[$_]->{data}})
				and looks_like_number(${$s[$_]->{data}}) 
		}
		return $s;	
	},
};
sub _check{
	my ($filter) = @_;
	return 1 unless defined $filter; #no filter, always returns true
	foreach (@$filter){
		return 0 unless _operation($_)
	}
	return 1;	#true
}

$indexesProc = {
	index => sub{
		my ($data, $index, $subpath,$filter) = @_;
		$index += $#$data + 1 if $index < 0;						# -1 == $#data => last index
		return () if $index < 0 or $index > $#$data;		# check bounds limits
		my @r = ();	
		push @context, {name => $index, data  => \$data->[$index]};
		sub{
			return if defined $filter and !_check($filter); 
			push @r, 
				defined $subpath ? 
					_getObjectSubset($data->[$index],$subpath)
					: $context[$#context];
		}->();
		pop @context;
		return @r;
	},
	range => sub{
		my ($data, $range, $subpath, $filter) = @_;
		my ($start, $stop) = @{$range};
		$start += $#$data + 1 if $start < 0;
		$stop += $#$data + 1 if $stop < 0;
		my @indexes = grep {$_ >=0 and $_ <= $#$data } $start <= $stop ?
			($start..$stop)
			: reverse ($stop..$start);
		my @r = ();
		push @r, $indexesProc->{index}->($data,$_,$subpath,$filter)
			foreach (@indexes);
		return @r;
	},
	from => sub{
		my ($data, $from, $subpath,$filter) = @_;
		$from += $#$data + 1 if $from < 0;
		$from = 0 if $from < 0;
		my @indexes = ($from..$#$data);
		my @r = ();
		push @r, $indexesProc->{index}->($data,$_,$subpath,$filter)
			foreach (@indexes);
		return @r;			
	},
	to => sub{
		my ($data, $to, $subpath,$filter) = @_;	
		$to += $#$data + 1 if $to < 0;
		$to = $#$data if $to > $#$data;
		my @indexes = (0..$to);
		my @r = ();
		push @r, $indexesProc->{index}->($data,$_,$subpath,$filter)
			foreach (@indexes);
		return @r;	
	},
	all => sub{
		my ($data, undef, $subpath,$filter) = @_;
		my @indexes = (0..$#$data);
		my @r = ();
		push @r, $indexesProc->{index}->($data,$_,$subpath,$filter)
			foreach (@indexes);
		return @r;	
	}
};

$keysProc = {
	step => sub{
		my ($data, $step, $subpath,$filter) = @_;
		return () unless exists $data->{$step};

		my @r = ();
		#$subpath->{currentObj} = $data->{$step} if defined $subpath;
		push @context, {name => $step, data  => \$data->{$step}};
		sub{	
			return if defined $filter and !_check($filter); 
			push @r, 
				defined $subpath ? 
					_getObjectSubset($data->{$step}, $subpath)
					: $context[$#context];
		}->();
		pop @context;
		return @r;
	},
	wildcard => sub{
		my ($data, undef, $subpath,$filter) = @_;
		my @r = ();
		push @r, $keysProc->{step}->($data, $_, $subpath,$filter)
			foreach (sort keys %$data);
		return @r;
	},
	dwildcard => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return descendent($data,$subpath,$filter);		
	},
	qq|..| => sub{
		my (undef, undef, $subpath,$filter) = @_;
		return () unless scalar @context > 1;
		push @context, $context[$#context-1];
		my @r = ();
		sub{	
			return if defined $filter and !_check($filter); 
			push @r, 
				defined $subpath ? 
					_getObjectSubset(${$context[$#context]->{data}}, $subpath)
					: $context[$#context];
		}->();		
		pop @context;
		return @r;	
	} 
};
sub descendent{ 
	my ($data,$subpath,$filter) = @_;
	return () unless defined $data;
	my @r = ();
	if (ref $data eq q|HASH|){
		foreach (sort keys %$data){
			push @r, $keysProc->{step}->($data, $_, $subpath,$filter);			#process this key entry
			push @context, {name => $_, data  => \$data->{$_}};							#create a context for next level
			push @r, descendent($data->{$_},$subpath,$filter);							#process descendents
			pop @context;		
		}
	}
	if (ref $data eq q|ARRAY|){
		foreach (0..$#$data){
			push @r, $indexesProc->{index}->($data,$_,$subpath,$filter);		#process this array index
			push @context, {name => $_, data  => \$data->[$_]};							#create a context for next level
			push @r, descendent($data->[$_],$subpath,$filter);							#process descendents
			pop @context;
		}
	};
	return @r;
}
sub _getObjectSubset{
	my ($data,$path) = @_;
	return () unless ref $path eq q|HASH|;
	#push @context, {path => $path, data  => \$data};
	#print 'Context ', Dumper \@context;
	my @r = ();
	if (ref $data eq q|HASH| or ref $data eq q|ARRAY| and exists $path->{dwildcard}){
		my @keys = grep{exists $path->{$_}} keys %$keysProc; 								
		push @r, $keysProc->{$_}->($data, $path->{$_}, $path->{subpath}, $path->{filter})
			foreach (@keys);		#$#keys = 1 always but let it to be generic
	}elsif(ref $data eq q|ARRAY| and defined $path->{indexes} and ref $path->{indexes} eq q|ARRAY|){
		my $indexes = $path->{indexes};
		foreach my $entry (@$indexes){
			push @r, $indexesProc->{$_}->($data,$entry->{$_},$path->{subpath},$path->{filter})
				foreach (grep {exists $indexesProc->{$_}} keys %$entry); 	#just in case use grep to filter out not supported indexes types
		}
	}elsif (exists $path->{q|..|}){
			push @r, $keysProc->{q|..|}->($data, $path->{q|..|}, $path->{subpath}, $path->{filter});
	}else{ #aqui deve-se por outro teste para o caso .. e .
		#do nothing. Nothing is ok
		#print 'Nothing ', Dumper $data;
	}
	#pop @context;
	return @r;
}
sub _getSubObjectsOrCurrent{
	my $paths = $_[0];
	return _getObjects(@$paths) if defined $paths and ref $paths eq q|ARRAY| and scalar @$paths > 0;
	return ($context[$#context]);
}
sub _getObjects{
		my @paths = @_;
		my @r = ();
		foreach my $entry (@paths){
			my $data = ${$context[defined $entry->{absolute} ? 0 : $#context]->{data}};
			push @r, _getObjectSubset($data,$entry->{path});
		}
		return @r;
}

###########object based invocation methods ########################
sub _execute{
	my ($self,$data,$query) = @_;
	return undef unless ref $data eq q|HASH| or ref $data eq q|ARRAY|; 
	return undef unless defined $query and (defined $query->{oper} or defined $query->{paths});
	push @context, {data  => \$data};
	my @r = defined $query->{oper} ? 
		map {\$_} (_operation($query))								#if an operation	
		: map {$_->{data}} _getObjects(@{$query->{paths}}); 	#else is a path
	pop @context;
	return Data::pQuery::Results->new(@r);
}

#########################################public methods ###################################################################
sub new {} 				#The Marpa::R2 needs it
sub compile{
	my ($self,$q) = @_; 
	return undef unless $q;

	my $reader = Marpa::R2::Scanless::R->new({
		grammar => $grammar,
		trace_terminals => 0,
	});
	$q =~ s/[#\N{U+A0}-\N{U+10FFFF}]/sprintf "#%d#", ord $&/ge; #code utf8 characters with sequece #utfcode#. Marpa problem? 
	$reader->read(\$q);
	my $qp = $reader->value;
	return Data::pQuery::Data->new(${$qp})
}

sub data{
	my ($self,$data) = @_;
	return Data::pQuery::Compiler->new($data)
}

sub DESTROY{
}

package Data::pQuery::Compiler;
use Data::Dumper;
sub new{
	my ($self,$data) = @_;
	return undef unless defined $data and (ref $data eq q|HASH| or ref $data eq q|ARRAY|); 
	return bless {data=>$data}, $self;
}

sub query{
	my ($self,$pQueryString) = @_;
	my $c = Data::pQuery->compile($pQueryString);
	return $c->data($self->{data});	
}
sub DESTROY{
}


package Data::pQuery::Data;
use Data::Dumper;

sub new{
	my ($self,$pQuery) = @_;
	return undef unless defined $pQuery and (defined $pQuery->{oper} or defined $pQuery->{paths});
	return bless {pQuery=>$pQuery}, $self;
}

sub data{
	my ($self,$data) = @_;
	return Data::pQuery->_execute($data,$self->{pQuery});
}

sub DESTROY{
}

package Data::pQuery::Results;
use Data::Dumper;

sub new {
	my ($self,@results) = @_;
	return bless {results=>[@results]}, $self;
}

sub getrefs{
	my $self = shift;
	return @{$self->{results}};
}
sub getref{
	my $self = shift;
	return $self->{results}->[0];
}
sub getvalues{
	my $self = shift;
	return map {$$_} @{$self->{results}};
}
sub getvalue{
	my $self = shift;
	return undef unless ref $self->{results}->[0];
	return ${$self->{results}->[0]};
}

1;
__END__

=head1 NAME

Data::pQuery - a xpath like processor for perl data-structures (hashes and arrays)! 

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

How to use it.

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

	print $data->query(q|*/*[..]|)->getvalues(); #the leading slash is optional
	#Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

	#Curly brackets are used to specify filters
	print $data->query(q|/*/*{isScalar()}|)->getvalues();
	#not allowed

	#data at any level could be specified by the sequence **
	print $data->query(q|**{isScalar()}|)->getvalues();
	#not allowed,Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

	#negative values indexes the arrays in reverse order. -1 is the last index
	print $data->query(q|/*/*[-1]|)->getvalues();
	#Coke,pears,tomatoes

	#the filter could be a match between a string expression and a pattern
	print $data->query(q|/*/*{name() ~ "drinks"}[..]|)->getvalues();
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
	print Dumper $data->query(q|
		/*/*
		{value([-1]) gt value([0])}
		{count([..]) < 4}
	|)->getvalues();
	=pod
	$VAR1 = [
	          'potatoes',
	          'carrots',
	          'tomatoes'
	        ];
	=cut

	#the same as above but using a logical operation instead of two filters
	print Dumper $data->query(q|
		/*/*{value([-1]) gt value([0]) 
			and count([..]) < 4
		}
	|)->getvalues();

	#a query could be a function instead of a path
	print $data->query(q|names(/*/*)|)->getvalues();
	#Alcoholic beverage,Soft drinks,fruit,vegetables

	#the function 'names' returns the keys names or indexes
	print $data->query(q|names(/**)|)->getvalues();
	#drinks,Alcoholic beverage,Soft drinks,0,1,food,fruit,0,1,2,3,vegetables,0,1,2


=head1 DESCRIPTION

It looks for data-structures which match the pQuery expression and returns a list
of matched data-structures.

The pQuery sintax is very similar to the xpath but with some exceptions. 
The square brackets '[]' are used to indexes arrays unlike xpath where they are 
used to specify predicates.

To specify filters (predicates in xpath nomenclature) pQuery uses curly brackets 
'{}'

The pQuery does not support paths of variable length '//' but instead it provides 
o double wildcard to match any nested data (descendent nodes in xpath nomenclature).
So instead of xpath expression //a the pQuery uses /**/a and instead of 
*[count(b) = 1] pQuery uses *{count() == 1}. Notice the double equal operator. 

Furthermore, pQuery does not cast anything, so is impossible to compare string expressions 
with mumeric expressions or using numeric operatores. If a function returns a string
it mus be compared with string operatores against another string expression, ex:
*{name() eq "keyname"}. 

Like xpath it is possible to deal with any logical or arithmetic 
expressions, ex: *{count(a) == count(c) / 2 * (1 + count(b)) or d}


=head1 METHODS

The Data::pQuery just provides two useful methods, compile and data. 
The first is used to complie a pQuery expression and the second is used
to prepare data to be queried. 

=head2 Data::pQuery methods

=head3 new(pQuery)

Used only internally!!! Do nothing;

=head3 compile(pQueryString)

	my $query = Data::pQuery->compile('*'); 			#compile the query
	
	my @values1 = $query->data({fruit => 'bananas'})->getvalues();
	# @values1 = (bananas)

	my @values2 = $query->data({
		fruit => 'bananas', 
		vegetables => 'orions'
	})->getvalues();
	# @values2 = (bananas, orions)

	my @values3 = $query->data({
		food => {fruit => 'bananas'}
	})->getvalues();
	# @values3 = ({fruit => 'bananas'})

The compile method receives a pQuery string, compiles it and returns a Data::pQuery::Data object.
This is the prefered method to run the same query over several data-structures.

=head3 data(dataRef)

	my $data = Data::pQuery->data({
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

	#using a filter, to get only first level entry which contains a fruit key
	my @values3 = $data->query('/*{fruit}/*')->getvalues();
	print @values3; #bananas,unions
	#using another filter to return only elements which have the value matching 
	#a /an/ pattern
	my @values4 = $data->query('/*/*{value() ~ "an"}')->getvalues();
	print @values4;# Evian,bananas

	my @values5 = $data->query('/**{isScalar()}')->getvalues();
	print @values5;#Evian,Porto,bananas,unions

                  

The method data receives a hash or array reference and returns a Data::pQuery::Compile object. 
This is the prefered method to run several query over same data.

=head2 Data::pQuery::Data methods

=head3 data(data)

Executes the query over data and returns a Data::pQuery::Results object

=head2 Data::pQuery::Compiler methods

=head3 query(pQueryString)

Compile a pQuery string, query the data and returns a Data::pQuery::Results object

=head2 Data::pQuery::Results methods

=head3 getrefs()
Returns a list os references for each matched data;

=head3 getref()
Returns a reference for first matched data;

=head3 getvalues()
Returns a list of values for each matched data;

=head3 getvalue()
Returns the value of first matched data;

=head1 pQuery sintax
	
A pQuery expression is a function or a path. 

=head2 pQuery Path Expressions

A path is a sequence of steps. A step represent a hash's key name or an array 
index. 

A array index is represented inside square brackets.

Two successive key names are separated by a slash.

	my $d = {
	        food => {
	                fruit => q|bananas|,
	                vegetables => [qw|potatoes  carrots tomatoes onions|]
	        }
	};
	my $data = Data::pQuery->data($d);

	my $food = $data->query('/food')->getref();
	$$food->{drinks} = q|no drinks|;

	my $fruit = $data->query('/food/fruit')->getref();
	$$fruit = 'pears';

	my $vegetables = $data->query('/food/vegetables')->getref();
	push @$$vegetables, q|garlic|;

	my $vegetable = $data->query('/food/vegetables[1]')->getref();
	$$vegetable = q|spinach|;

	print Dumper $d;

The above code will produce the result

	$VAR1 = {
	          'food' => {
	                      'drinks' => 'no drinks',
	                      'fruit' => 'pears',
	                      'vegetables' => [
	                                        'potatoes',
	                                        'spinach',
	                                        'tomatoes',
	                                        'onions',
	                                        'garlic'
	                                      ]
	                    }
	        };


A wildcard (*) means any key name and a double wildcard (**) means any key name
or any index nested inside current data-structure. 

	my $d = {
	        food => {
	                fruit => q|bananas|,
	                vegetables => [qw|potatoes  carrots|]
	        },
	        wine => 'Porto'
	};
	my $data = Data::pQuery->data($d);

	my @all = $data->query('*')->getvalues();
	print "all\t", Dumper \@all;

	my @deepall = $data->query('**')->getvalues();
	print "deepall\t", Dumper \@deepall;

The above code will produce the following result

	all	$VAR1 = [
	          {
	            'fruit' => 'bananas',
	            'vegetables' => [
	                              'potatoes',
	                              'carrots'
	                            ]
	          },
	          'Porto'
	        ];
	deepall	$VAR1 = [
	          {
	            'fruit' => 'bananas',
	            'vegetables' => [
	                              'potatoes',
	                              'carrots'
	                            ]
	          },
	          'bananas',
	          [
	            'potatoes',
	            'carrots'
	          ],
	          'potatoes',
	          'carrots',
	          'Porto'
	        ];

The arrays can be index by one or more indexes separated by a comma.

The indexes can be negative which will be interpreted as reverse index. 
The -1 indexes last array position, -2 indexes second last and so one.  

It's possible to index a range by specifying the limits separated by a 
dotdot sequence. 
If first limit is greater than last the result will be returned in reverse 
order. 
If left limit is omitted it means start from first index.
If right limit is omitted it means stop on last index.
Its' also possible to index any combination of ranges and indexes separated
by commas

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

Every step could be filter out by a logical expression inside a curly bracket. 

A logical expression is any combination of comparison expressions, path 
expressions, or logical functions, combined with operators 'and' and 'or'


=head3 Comparison expressions

A comparison expression can compare two strings expressions or two numeric 
expressions. Its impossible to compare a string expression with a numeric 
expression. Nothing is cast! It is also impossible to use numeric comparison
operator to compare strings expressions.

=head4 Numeric comparison operators

=over 8

=item 	NumericExpr < NumericExpr	

=item   NumericExpr <= NumericExpr							

=item  NumericExpr > NumericExpr							

=item 	NumericExpr >= NumericExpr

=item  NumericExpr == NumericExpr							

=item 	NumericExpr != NumericExpr							

=back

=head4 String comparison operators

=over 8 

=item  StringExpr lt StringExpr							

=item  StringExpr le StringExpr							

=item  StringExpr gt StringExpr							

=item  StringExpr ge StringExpr							

=item  StringExpr ~ RegularExpr							

=item  StringExpr !~ RegularExpr							

=item  StringExpr eq StringExpr							

=item  StringExpr ne StringExpr	

=back

=head2 pQuery Functions
	
Any function can be used as query  and some of them can also
be used as part of a numeric or string expression inside a filter.

Currently only the following function are supported 
=over 4
=item count(pathExpr)
Counts the number of matched data-structures

=item names(pathExpr?)

Returns a list of names of matched data-structures. 
If pathExpr is omitted it returns the name of current data-structure. 
If the data-structure is a hash entry it returns the keyname.
If the data-structure is an array entry it returns the index.
PathExpr is any valid pQuery path expression. 
If it starts with a slash it means an absolute path, otherwise it is a 
path relative to the current data-structure.
A empty list will be returned if nothing matches.   

=item name(pathExpr?)

name is a particular case of names which just returns the name of first matched 
data-structure or undef if nothing matches. 

This function can be part of a string expression inside a filter

=item values(pathExpr?)
 
Like names but returns the values instead of keys or indexs. 
The same rules apllies for the optional pathExpr argument.

=item value(pathExpr?)

Returns the value of first matched data-structure or undef in none matches.
If pathExpr is omitted it returns the value of current data-structure.  

This function can be part of a string expression or a numeric expression inside a filter

=item isXXXX(pathExpr?)

Thet set of functions isXXX() returns true is the matched data-structure is a variable of 
correspondent type. This is the currently implemented list: isRef, isScalar, 
isHash, isArray and isCode.

If pathExpr is omitted it applies to current data-structure. 
If pathExpr evaluates to more than one data-strucures it returns the result of a internal 
logical or operation. For instance, the pQuery expression a{isScalar(*)} returns the 
data-structure referenced by the 'a' keyname if it contains at least one key associated 
with a scalar value. 

=head2 pQuery grammar

Marpa::R2 is used to parse the pQuery expression. Bellow is the complete grammar

	:start ::= Start

	Start ::= OperExp                             

	OperExp ::=
	  PathExpr                                    
	  |Function                                   

	Function ::=
	  NumericFunction                             
	  | StringFunction                            
	  | ListFunction                              

	PathExpr ::=
	  absolutePath                                
	  | relativePath                              
	  | PathExpr '|' PathExpr                     

	relativePath ::=  
	  stepPath                                    
	  | indexPath                                 

	absolutePath ::=  
	  '/' stepPath                                
	  | indexPath                                 

	stepPath ::=
	  step Filter absolutePath                    
	  | step Filter                               
	  | step absolutePath                         
	  | step                                      

	step ::= 
	  keyname                                     
	  | wildcard                                  
	  | dwildcard                                 
	  | '..'                                      

	indexPath ::=
	  IndexArray Filter absolutePath              
	  | IndexArray Filter                         
	  | IndexArray absolutePath                   
	  | IndexArray                                


	IndexArray ::=  '[' IndexExprs ']'            


	IndexExprs ::= IndexExpr+       separator => <comma>

	IndexExpr ::=
	  IntExpr                                     
	  | rangeExpr                                 

	rangeExpr ::= 
	  IntExpr '..' IntExpr                        
	  |IntExpr '..'                               
	  | '..' IntExpr                              
	  | '..'                                      


	Filter ::=  
	  '{' LogicalExpr '}'                         
	  | '{' LogicalExpr '}' Filter                

	IntExpr ::=
	  ArithmeticIntExpr                           

	 ArithmeticIntExpr ::=
	  INT                                         
	  | IntegerFunction                           
	  | '(' IntExpr ')'                           
	  || '-' ArithmeticIntExpr                    
	   | '+' ArithmeticIntExpr                    
	  || ArithmeticIntExpr '*' ArithmeticIntExpr  
	   | ArithmeticIntExpr '/' ArithmeticIntExpr  
	   | ArithmeticIntExpr '%' ArithmeticIntExpr  
	  || ArithmeticIntExpr '+' ArithmeticIntExpr  
	   | ArithmeticIntExpr '-' ArithmeticIntExpr  


	NumericExpr ::=
	  ArithmeticExpr                              

	ArithmeticExpr ::=
	  NUMBER                                      
	  | NumericFunction                           
	  | '(' NumericExpr ')'                       
	  || '-' ArithmeticExpr                       
	   | '+' ArithmeticExpr                       
	  || ArithmeticExpr '*' ArithmeticExpr        
	   | ArithmeticExpr '/' ArithmeticExpr        
	   | ArithmeticExpr '%' ArithmeticExpr        
	  || ArithmeticExpr '+' ArithmeticExpr        
	   | ArithmeticExpr '-' ArithmeticExpr        

	LogicalExpr ::=
	  compareExpr                                 
	  |LogicalFunction                            

	compareExpr ::= 
	  PathExpr                                    
	  || NumericExpr '<' NumericExpr              
	   | NumericExpr '<=' NumericExpr             
	   | NumericExpr '>' NumericExpr              
	   | NumericExpr '>=' NumericExpr             
	   | StringExpr 'lt' StringExpr               
	   | StringExpr 'le' StringExpr               
	   | StringExpr 'gt' StringExpr               
	   | StringExpr 'ge' StringExpr               
	   | StringExpr '~' RegularExpr               
	   | StringExpr '!~' RegularExpr              
	   | NumericExpr '==' NumericExpr             
	   | NumericExpr '!=' NumericExpr             
	   | StringExpr 'eq' StringExpr               
	   | StringExpr 'ne' StringExpr               
	  || compareExpr 'and' LogicalExpr            
	  || compareExpr 'or' LogicalExpr             

	#operator match, not match, in, intersect and union are missing

	StringExpr ::=
	  STRING                                      
	  | StringFunction                            
	  || StringExpr '||' StringExpr               


	RegularExpr 
	  ::= STRING                                  

	LogicalFunction ::=
	  'not' '(' LogicalExpr ')'                   
	  | 'isRef' '('  PathArgs  ')'                
	  | 'isScalar' '(' PathArgs ')'               
	  | 'isArray' '(' PathArgs ')'                
	  | 'isHash' '(' PathArgs ')'                 
	  | 'isCode' '(' PathArgs ')'                 

	StringFunction ::=
	  NameFunction                                
	  | ValueFunction                             

	NameFunction ::= 
	  'name' '(' PathArgs ')'                     

	PathArgs ::= 
	  PathExpr                                    
	  |EMPTY                                      

	EMPTY ::=

	ValueFunction ::= 
	  'value' '(' PathArgs ')'                    

	CountFunction ::= 
	  'count' '(' PathExpr ')'                    

	SumFunction ::= 
	  'sum' '(' PathExpr ')'                      

	SumProductFunction ::= 
	  'sumproduct' '(' PathExpr ',' PathExpr ')'  

	NumericFunction ::=
	  CountFunction                               
	  |ValueFunction                              
	  |SumFunction                                
	  |SumProductFunction                         

	IntegerFunction ::=
	  CountFunction                               

	ListFunction ::=
	  'names' '(' PathArgs ')'                    
	  | 'values' '(' PathArgs ')'                 


	 NUMBER ::= 
	  unumber                                     
	  | '-' unumber                               
	  | '+' unumber                               

	unumber 
	  ~ uint
	  | uint frac
	  | uint exp
	  | uint frac exp
	 
	uint            
	  ~ digits

	digits 
	  ~ [\d]+
	 
	frac
	  ~ '.' digits
	 
	exp
	  ~ e digits
	 
	e
	  ~ 'e'
	  | 'e+'
	  | 'e-'
	  | 'E'
	  | 'E+'
	  | 'E-'

	INT ::= 
	  UINT                                    
	  | '+' UINT                              
	  | '-' UINT                              

	UINT
	  ~digits

	STRING ::= 
	  double_quoted                               
	  | single_quoted                             


	single_quoted        
	  ~ [''] single_quoted_chars ['']

	single_quoted_chars      
	  ~ single_quoted_char*
	 
	single_quoted_char  
	  ~ [^']
	  | '\' [']

	double_quoted        
	  ~ ["] double_quoted_chars ["]

	double_quoted_chars      
	  ~ double_quoted_char*
	 
	double_quoted_char  
	  ~ [^"]
	  | '\' '"'

	wildcard 
	  ~ [*]

	dwildcard 
	  ~ [*][*]

	keyname ::= 
	  token                                       
	  | STRING                                    

	token ~ [^./*,'"|\s\]\[\(\)\{\}\\+-]+


	:discard 
	  ~ WS

	WS 
	  ~ [\s]+

	comma 
	  ~ ','

=head1 AUTHOR

Isidro Vila Verde, C<< <jvverde at gmail.com> >>

=head1 BUGS

Send email to C<< <jvverde at gmail.com> >> with subject Data::pQuery


=begin futuro

Please report any bugs or feature requests to C<bug-data-pquery at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-pQuery>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=end futuro

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::pQuery


=begin tmp
You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-pQuery>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-pQuery>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-pQuery>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-pQuery/>

=back


=head1 ACKNOWLEDGEMENTS

=end tmp


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Isidro Vila Verde.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

