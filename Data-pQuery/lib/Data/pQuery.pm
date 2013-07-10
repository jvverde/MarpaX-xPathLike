package Data::pQuery;
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

Start	::= OperExp									action => _do_arg1

OperExp ::=
	PathExpr 										action => _do_path
	|Function 										action => _do_arg1

Function ::=
	NumericFunction									action => _do_arg1
	|StringFunction 								action => _do_arg1
	|ListFunction 									action => _do_arg1

PathExpr ::=
	singlePath										action => _do_singlePath
	| PathExpr '|' singlePath						action => _do_pushArgs2array

singlePath ::=	
	stepPath 										action => _do_arg1
	|indexPath 										action => _do_arg1

stepPath ::=
	step Filter subPathExpr 						action => _do_stepFilterSubpath
	| step Filter 									action => _do_stepFilter
	| step subPathExpr 								action => _do_stepSubpath
	| step											action => _do_arg1

step ::= 
	keyword 										action => _do_keyword
	| wildcard 										action => _do_wildcard
	| dwildcard 									action => _do_dwildcard	

subPathExpr ::= 
	'.' stepPath 									action => _do_arg2
	|indexPath 										action => _do_arg1

indexPath ::=
	IndexArray Filter subPathExpr 					action => _do_indexFilterSubpath	
	| IndexArray Filter 							action => _do_indexFilter	
	| IndexArray subPathExpr 						action => _do_indexSubpath		
	| IndexArray									action => _do_arg1	


IndexArray ::=  '[' IndexExprs ']'					action => _do_index


IndexExprs ::= IndexExpr+ 			separator => <comma>

IndexExpr ::=
	IntegerExpr										action => _do_index_single
	| rangeExpr										action => _do_arg1

rangeExpr ::= 
	IntegerExpr '..' IntegerExpr 					action => _do_index_range
	|IntegerExpr '...' 								action => _do_startRange
	| '...' IntegerExpr								action => _do_endRange
	| '...' 										action => _do_allRange


Filter ::= 	
	'{' LogicalExpr '}' 							action => _do_filter
	| '{' LogicalExpr '}' Filter 					action => _do_mergeFilters

IntegerExpr ::=
  ArithmeticIntegerExpr										action => _do_arg1

 ArithmeticIntegerExpr ::=
 	INT 													action => _do_arg1
	| IntegerFunction										action => _do_arg1
	| '(' IntegerExpr ')' 									action => _do_group
	|| '-' ArithmeticIntegerExpr 							action => _do_unaryOperator
	 | '+' ArithmeticIntegerExpr 							action => _do_unaryOperator
	|| ArithmeticIntegerExpr '*' ArithmeticIntegerExpr		action => _do_binaryOperation
	 | ArithmeticIntegerExpr '/' ArithmeticIntegerExpr		action => _do_binaryOperation
	 | ArithmeticIntegerExpr '%' ArithmeticIntegerExpr		action => _do_binaryOperation
	|| ArithmeticIntegerExpr '+' ArithmeticIntegerExpr		action => _do_binaryOperation
	 | ArithmeticIntegerExpr '-' ArithmeticIntegerExpr		action => _do_binaryOperation


NumericExpr ::=
  ArithmeticExpr 											action => _do_arg1

ArithmeticExpr ::=
	NUMBER 													action => _do_arg1
	| NumericFunction										action => _do_arg1
	| '(' NumericExpr ')' 									action => _do_group
	|| '-' ArithmeticExpr 									action => _do_unaryOperator
	 | '+' ArithmeticExpr 									action => _do_unaryOperator
	|| ArithmeticExpr '*' ArithmeticExpr					action => _do_binaryOperation
	 | ArithmeticExpr '/' ArithmeticExpr					action => _do_binaryOperation
	 | ArithmeticExpr '%' ArithmeticExpr					action => _do_binaryOperation
	|| ArithmeticExpr '+' ArithmeticExpr					action => _do_binaryOperation
	 | ArithmeticExpr '-' ArithmeticExpr					action => _do_binaryOperation

LogicalExpr ::=
	compareExpr												action => _do_arg1
	|LogicalFunction										action => _do_arg1

compareExpr ::=	
	PathExpr 												action => _do_exists
	|| NumericExpr '<' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '<=' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '>' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '>=' NumericExpr							action => _do_binaryOperation
	 | StringExpr 'lt' StringExpr							action => _do_binaryOperation
	 | StringExpr 'le' StringExpr							action => _do_binaryOperation
	 | StringExpr 'gt' StringExpr							action => _do_binaryOperation
	 | StringExpr 'ge' StringExpr							action => _do_binaryOperation
	 | StringExpr '~' RegularExpr							action => _do_binaryOperation
	 | StringExpr '!~' RegularExpr							action => _do_binaryOperation
	 | NumericExpr '==' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '!=' NumericExpr							action => _do_binaryOperation
	 | StringExpr 'eq' StringExpr							action => _do_binaryOperation
	 | StringExpr 'ne' StringExpr							action => _do_binaryOperation
	|| compareExpr 'and' LogicalExpr						action => _do_binaryOperation
	|| compareExpr 'or' LogicalExpr							action => _do_binaryOperation

#operator match, not match, in, intersect, union,

StringExpr ::=
	STRING 													action => _do_arg1
 	| StringFunction 										action => _do_arg1
 	|| StringExpr '||' StringExpr  							action => _do_binaryOperation

LogicalFunction ::=
	'not' '(' LogicalExpr ')'			 					action => _do_func
	| 'isRef' '('  PathArgs  ')'			 					action => _do_func
	| 'isScalar' '(' PathArgs ')'			 				action => _do_func
	| 'isArray' '(' PathArgs ')'			 				action => _do_func
	| 'isHash' '(' PathArgs ')'			 					action => _do_func
	| 'isCode' '(' PathArgs ')'								action => _do_func

StringFunction ::=
	NameFunction											action => _do_arg1
	| ValueFunction											action => _do_arg1

NameFunction ::= 
	'name' '(' PathArgs ')'				 					action => _do_func

PathArgs ::= 
	PathExpr						  						action => _do_arg1
	|EMPTY													action => _do_arg1

EMPTY ::=

ValueFunction ::= 
	'value' '(' PathArgs ')'				 				action => _do_func

CountFunction ::= 
	'count' '(' PathExpr ')'				 				action => _do_func

SumFunction ::= 
	'sum' '(' PathExpr ')'				 					action => _do_func

SumProductFunction ::= 
	'sumproduct' '(' PathExpr ',' PathExpr ')'				action => _do_funcw2args

NumericFunction ::=
	CountFunction											action => _do_arg1
	|ValueFunction											action => _do_arg1
	|SumFunction											action => _do_arg1
	|SumProductFunction										action => _do_arg1

IntegerFunction ::=
	CountFunction											action => _do_arg1

ListFunction ::=
	'names' '(' PathArgs ')'    		 					action => _do_func
	| 'values' '(' PathArgs ')'    		 					action => _do_func


 NUMBER ::= UNUMBER 										action => _do_arg1
 	| '-' UNUMBER 											action => _do_join
 	| '+' UNUMBER 											action => _do_join

UNUMBER  
	~ unumber       

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
	UINT 											action => _do_arg1
	| '+' UINT  									action => _do_join
	| '-' UINT  									action => _do_join

UINT
	~digits

STRING       ::= lstring               				action => _do_string
RegularExpr ::= regularstring						action => _do_re
regularstring ~ delimiter re delimiter				

delimiter ~ [/]

re ~ char*

char ~ [^/\\]
 	| '\' '/'
 	| '\\'


lstring        ~ quote in_string quote
quote          ~ ["]
 
in_string      ~ in_string_char*
 
in_string_char  ~ [^"\\]
	| '\' '"'
	| '\\'

comma ~ ','

wildcard ~ [*]
dwildcard ~ [*][*]

keyword ~ [a-zA-Z\N{U+A1}-\N{U+10FFFF}]+

:discard ~ WS
WS ~ [\s]+

END_OF_SOURCE
});


sub _do_arg1{ return $_[1]};
sub _do_arg2{ return $_[2]};

sub _do_path{
	return {path => $_[1]}	
}
sub _do_re{
	my $re = $_[1];
	$re =~ s/^\/|\/$//g;
	return qr/$re/;
}
sub _do_string {
    my $s = $_[1]; 
    $s =~ s/^"|"$//g;
    return $s;
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
sub _do_pushArgs2array{
	my ($a,$b) = @_[1,3];
	my @array = (@$a,$b);
	return \@array;
}
sub _do_singlePath{
	return [$_[1]];
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
sub _do_keyword{
	my $k = $_[1];
	return {step => $k};
}

sub _do_wildcard{
	my $k = $_[1];
	return {wildcard => $k};
}
sub _do_dwildcard{
	my $k = $_[1];
	return {dwildcard => $k};
}
######################################################end of rules######################################################3

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
		return map {$_->{step}} _getSubObjectsOrCurrent(@_);
	},
	name => sub{
		my @r = $operatorBy->{names}->(@_);
		return $r[0] if defined $r[0];
		return q||; 
	},
	value => sub(){
		my @r = $operatorBy->{values}->(@_);
		return $r[0] if defined $r[0];
		return q||; 
	},
	values => sub{
		return map {${$_->{data}}} _getSubObjectsOrCurrent(@_);
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
sub _getSubObjectsOrCurrent{
	my $paths = $_[0];
	my @r = ();
	return ($context[$#context]) if scalar @$paths == 0;
	foreach my $path (@$paths){
		my @objs = _getObjectSubset(${$context[$#context]->{data}},$path);
		foreach my $obj (@objs){
			push @r, $obj;
		}	
	}
	return @r;
}
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
		$index += $#$data + 1 if $index < 0;
		return () unless $data->[$index];
		my @r = ();	
		#$subpath->{currentObj} = $data->[$index] if defined $subpath;
		push @context, {step => $index, data  => \$data->[$index], type => q|index|};
		sub{
			return if defined $filter and !_check($filter); 
			push @r, 
				defined $subpath ? 
					_getObjectSubset($data->[$index],$subpath)
					:{data => \$data->[$index], step => $index, context => [@context]}
		}->();
		pop @context;
		return @r;
	},
	range => sub{
		my ($data, $range, $subpath, $filter) = @_;
		my ($start, $stop) = @{$range};
		$start += $#$data + 1 if $start < 0;
		$stop += $#$data + 1 if $stop < 0;
		$stop = $#$data if $stop > $#$data;
		my @indexes = $start <= $stop ?
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
		my @indexes = ($from..$#$data);
		my @r = ();
		push @r, $indexesProc->{index}->($data,$_,$subpath,$filter)
			foreach (@indexes);
		return @r;			
	},
	to => sub{
		my ($data, $to, $subpath,$filter) = @_;	
		$to += $#$data + 1 if $to < 0;
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
		push @context, {step => $step, data  => \$data->{$step}, type => q|key|};
		sub{	
			return if defined $filter and !_check($filter); 
			push @r, 
				defined $subpath ? 
					_getObjectSubset($data->{$step}, $subpath)
					: {data => \$data->{$step}, step => $step, context => [@context]};
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
	} 
};
sub descendent{
	my ($data,$subpath,$filter) = @_;
	my @r = ();
	if (defined $data and ref $data eq q|HASH|){
		foreach (sort keys %$data){
			push @r, $keysProc->{step}->($data, $_, $subpath,$filter);
			push @r, descendent($data->{$_},$subpath,$filter);		
		}
	}
	if (defined $data and ref $data eq q|ARRAY|){
		foreach (0..$#$data){
			push @r, $indexesProc->{index}->($data,$_,$subpath,$filter);
			push @r, descendent($data->[$_],$subpath,$filter);
		}
	};
	return @r;
}
sub _getObjectSubset{
	my ($data,$path) = @_;
	return () unless ref $path eq q|HASH|;
	my @r = ();
	if (ref $data eq q|HASH| or ref $data eq q|ARRAY| and exists $path->{dwildcard}){
		my @keys = grep{exists $path->{$_}} keys %$keysProc; 								#$#keys = 1 always but let it to be generic
		push @r, $keysProc->{$_}->($data, $path->{$_}, $path->{subpath}, $path->{filter})
			foreach (@keys);
	}elsif(ref $data eq q|ARRAY|){
		my $indexes = $path->{indexes};
		return () unless defined $indexes;
		foreach my $entry (@$indexes){
			push @r, $indexesProc->{$_}->($data,$entry->{$_},$path->{subpath},$path->{filter})
				foreach (grep {exists $indexesProc->{$_}} keys %$entry); 	#just in case use grep to filter out not supported indexes types
		}
	}else{
		#ignore
		#warn q|Data arg is not a HASH ref or ARRAY ref|;
	}
	return @r;
}

sub _getObjects{
		return map {_getObjectSubset($_[0],$_)}  (@_[1..$#_]);
}

###########object based invocation methods ########################
sub _execute{
	my ($self,$data,$query) = @_;
	return undef unless ref $data eq q|HASH| or ref $data eq q|ARRAY|; 
	return undef unless defined $query and (defined $query->{oper} or defined $query->{path});
	push @context, {data  => \$data};
	#print "struct ", Dumper $self->{query};
	my @r = defined $query->{oper} ? 
		map {\$_} (_operation($query))								#if an operation	
		: map {$_->{data}} _getObjects($data, @{$query->{path}}); 	#else is a path
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
	$reader->read(\$q);
	my $qp = $reader->value;
	#print Dumper $qp;
	return Data::pQuery::Data->new(${$qp})
}

sub data{
	my ($self,$data) = @_;
	return Data::pQuery::Compiler->new($data)
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


package Data::pQuery::Data;
use Data::Dumper;

sub new{
	my ($self,$pQuery) = @_;
	return undef unless defined $pQuery and (defined $pQuery->{oper} or defined $pQuery->{path});
	return bless {pQuery=>$pQuery}, $self;
}

sub data{
	my ($self,$data) = @_;
	return Data::pQuery->_execute($data,$self->{pQuery});
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
	return ${$self->{results}->[0]};
}

1;
__END__

=head1 NAME

Data::pQuery - a xpath like processor for json like data-objects (hashes and arrays)! 

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

How to use it.

	use Data::pQuery;

	($\,$,) = ("\n",",");
	my $query = Data::pQuery->compile('a.*');
	my $data = {
	        a => {
	                b => 'bb',
	                c => 'cc'
	        },
	        aa => 'aa'
	};
	my $results = $query->data($data);
	my @values = $results->getvalues();
	print @values;                          #outputs 'bb,cc'
	my $ref = $results->getref();
	$$ref = 'new value';
	print $data->{a}->{b};                  #outputs 'new value'


=head1 METHODS

The Data::pQuery just provides two methods

=head2 Data::pQuery methods


=head3 new(pQuery)

Used only internally!!! Do nothing;

=head3 compile(pQueryString)

	my $query = Data::pQuery->compile('*');
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

Receives a pQuery string compile it and return a Data::pQuery::Data object.
We should prefer this method if we want to run the same query over several data-objects.

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
	my @values1 = $data->query('*.*')->getvalues();
	print @values1; # Evian,Porto,bananas,unions

	my @values2 = $data->query('*.wine')->getvalues();
	print @values2; # Porto

	#using a filter {condition}.  
	my @values3 = $data->query('*{fruit}.*')->getvalues();
	print @values3; # bananas,unions

	#using another filter
	my @values4 = $data->query('*.*{value() ~ /an/}')->getvalues();
	print @values4; # Evian,bananas

	#using a variable length path (**) and a filter
	my @values5 = $data->query('**{isScalar()}')->getvalues();
	print @values5;#Evian,Porto,bananas,unions
                  

Receives a hash or array reference and return a Data::pQuery::Compile object. 
We should prefer this method if we want to run the several queries over same data-objects.


=head2 Data::pQuery::Data methods

=head3 data(data)

Executes the query over data and returns a Data::pQuery::Results object


=head2 Data::pQuery::Compiler methods

=head3 query(pQueryString)

Compile a pQuery string, query the data and returns a Data::pQuery::Results object

=head2 Data::pQuery::Results methods

=head3 getrefs()
Returns a list os references for each matched data-object;

=head3 getref()
Returns a reference for first matched data-object;

=head3 getvalues()
Returns a list of values for each matched data-object;

=head3 getvalue()
Returns the value of first matched data-object;

=head1 pQuery sintax
	
A pQuery expression is a function or a path. 

=head2 pQuery Path Expressions

A path is a sequence of steps. A step represent a hash's key name or an array 
index. 

A array index is represented inside square brackets.

Two succesive key names are separated by a dot.

	my $d = {
	        food => {
	                fruit => q|bananas|,
	                vegetables => [qw|potatoes  carrots tomatoes onions|]
	        }
	};
	my $data = Data::pQuery->data($d);

	my $food = $data->query('food')->getref();
	$$food->{drinks} = q|no drinks|;

	my $fruit = $data->query('food.fruit')->getref();
	$$fruit = 'pears';

	my $vegetables = $data->query('food.vegetables')->getref();
	push @$$vegetables, q|garlic|;

	my $vegetable = $data->query('food.vegetables[1]')->getref();
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
or any index under current object. 

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

=item	NumericExpr > NumericExpr							

=item 	NumericExpr >= NumericExpr

=item	NumericExpr == NumericExpr							

=item 	NumericExpr != NumericExpr							

=back

=head4 String comparison operators

=over 8 

=item	StringExpr lt StringExpr							

=item	StringExpr le StringExpr							

=item	StringExpr gt StringExpr							

=item	StringExpr ge StringExpr							

=item	StringExpr ~ RegularExpr							

=item	StringExpr !~ RegularExpr							

=item	StringExpr eq StringExpr							

=item	StringExpr ne StringExpr	

=back

=head2 pQuery Functions 

=head2 pQuery grammar

Marpa::R2 is used to parse the pQuery expression. Bellow is the complete grammar

	:start ::= Start

	Start	::= OperExp									

	OperExp ::=
		PathExpr 										
		|Function 										

	Function ::=
		NumericFunction									
		|StringFunction 								
		|ListFunction 									

	PathExpr ::=
		singlePath										
		| PathExpr '|' singlePath						

	singlePath ::=	
		stepPath 										
		|indexPath 										

	stepPath ::=
		step Filter subPathExpr 						
		| step Filter 									
		| step subPathExpr 								
		| step											

	step ::= 
		keyword 										
		| wildcard 										
		| dwildcard 									

	subPathExpr ::= 
		'.' stepPath 									
		|indexPath 										

	indexPath ::=
		IndexArray Filter subPathExpr 					
		| IndexArray Filter 							
		| IndexArray subPathExpr 						
		| IndexArray										

	IndexArray ::=  '[' IndexExprs ']'					

	IndexExprs ::= IndexExpr+ 			

	IndexExpr ::=
		IntegerExpr										
		| rangeExpr										

	rangeExpr ::= 
		IntegerExpr '..' IntegerExpr 					
		|IntegerExpr '...' 								
		| '...' IntegerExpr								
		| '...' 										

	Filter ::= 	
		'{' LogicalExpr '}' 							
		| '{' LogicalExpr '}' Filter 					

	IntegerExpr ::=
	  ArithmeticIntegerExpr										

	 ArithmeticIntegerExpr ::=
	 	INT 													
		| IntegerFunction										
		| '(' IntegerExpr ')' 									
		|| '-' ArithmeticIntegerExpr 							
		 | '+' ArithmeticIntegerExpr 							
		|| ArithmeticIntegerExpr '*' ArithmeticIntegerExpr		
		 | ArithmeticIntegerExpr '/' ArithmeticIntegerExpr		
		 | ArithmeticIntegerExpr '%' ArithmeticIntegerExpr		
		|| ArithmeticIntegerExpr '+' ArithmeticIntegerExpr		
		 | ArithmeticIntegerExpr '-' ArithmeticIntegerExpr		


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

	#operator match, not match, in, intersect, union,

	StringExpr ::=
		STRING 													
	 	| StringFunction 										
	 	|| StringExpr '||' StringExpr  							

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


	 NUMBER ::= UNUMBER 										
	 	| '-' UNUMBER 											
	 	| '+' UNUMBER 											

	UNUMBER  
		~ unumber       

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

	STRING       ::= lstring               				
	RegularExpr ::= regularstring						
	regularstring ~ delimiter re delimiter				

	delimiter ~ [/]

	re ~ char*

	char ~ [^/\\]
	 	| '\' '/'
	 	| '\\'


	lstring        ~ quote in_string quote
	quote          ~ ["]
	 
	in_string      ~ in_string_char*
	 
	in_string_char  ~ [^"\\]
		| '\' '"'
		| '\\'

	comma ~ ','

	wildcard ~ [*]
	dwildcard ~ [*][*]

	keyword ~ [a-zA-Z\N{U+A1}-\N{U+10FFFF}]+

	:discard ~ WS
	WS ~ [\s]+

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

