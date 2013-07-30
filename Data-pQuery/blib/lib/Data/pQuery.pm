package Data::pQuery;
use utf8;
use open ":std", ":encoding(UTF-8)";
use 5.006;
use strict;
use Carp;
#use warnings FATAL => 'all';
use warnings;
use Marpa::R2;
use Data::Dumper;
use Scalar::Util qw{looks_like_number weaken};

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw();

our $VERSION = '0.1';

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

PredPathExpr ::=
	absolutePath																action => _do_absolutePath
	| stepPathNoDigitStart											action => _do_relativePath
	| './' stepPath															action => _do_relativePath2
	| PredPathExpr '|' PredPathExpr							action => _do_pushArgs2array

relativePath ::=	
	stepPath 																		action => _do_arg1

absolutePath ::=	
	subPath 																		action => _do_arg1

subPath ::=	
	'/' stepPath 																action => _do_arg2
	| '//' stepPath															action => _do_vlen

stepPath ::=
	step Filter subPath 												action => _do_stepFilterSubpath
	| step Filter 															action => _do_stepFilter
	| step subPath 															action => _do_stepSubpath
	| step																			action => _do_arg1


step ::= 
	keyOrAxis																		action => _do_arg1			
	|index 																			action => _do_arg1

index ::=
	UINT																				action => _do_array_hash_index

stepPathNoDigitStart ::= 	
	keyOrAxis Filter subPath 										action => _do_stepFilterSubpath
	| keyOrAxis Filter 													action => _do_stepFilter
	| keyOrAxis subPath 												action => _do_stepSubpath
	| keyOrAxis																	action => _do_arg1


keyOrAxis ::= 
	keyname 																	  action => _do_keyname
	| '[' UINT ']'															action => _do_array_index
	|	'.'																				action => _do_self
	|	'[.]'																			action => _do_selfArray
	|	'{.}'																			action => _do_selfHash
	| 'self::*'																	action => _do_self	
	| 'self::[*]'																action => _do_selfArray	
	| 'self::{*}'																action => _do_selfHash	
	| 'self::' keyname													action => _do_selfNamed	
	| 'self::' UINT															action => _do_selfIndexedOrNamed	
	| 'self::[' UINT ']'												action => _do_selfIndexed	
	| '*' 																			action => _do_child
	| '[*]' 																		action => _do_childArray
	| '{*}' 																		action => _do_childHash
	|	'child::*'																action => _do_child
	|	'child::[*]'															action => _do_childArray
	|	'child::{*}'															action => _do_childHash
	|	'child::' keyname													action => _do_childNamed
	|	'child::'	UINT														action => _do_childIndexedOrNamed
	|	'child::[' UINT ']'												action => _do_childIndexed
	|	'..'																			action => _do_parent
	|	'[..]'																		action => _do_parentArray
	|	'{..}'																		action => _do_parentHash
	| 'parent::*'																action => _do_parent
	| 'parent::[*]'															action => _do_parentArray
	| 'parent::{*}'															action => _do_parentHash
	| 'parent::' keyname												action => _do_parentNamed			  
	| 'parent::' UINT 													action => _do_parentIndexedOrNamed			  
	| 'parent::[' UINT ']'											action => _do_parentIndexed			  
	| 'ancestor::*'															action => _do_ancestor
	| 'ancestor::[*]'														action => _do_ancestorArray
	| 'ancestor::{*}'														action => _do_ancestorHash
	| 'ancestor::' keyname											action => _do_ancestorNamed
	| 'ancestor::' UINT													action => _do_ancestorIndexedOrNamed
	| 'ancestor::[' UINT ']'										action => _do_ancestorIndexed
	| 'ancestor-or-self::*'											action => _do_ancestorOrSelf
	| 'ancestor-or-self::[*]'										action => _do_ancestorOrSelfArray
	| 'ancestor-or-self::{*}'										action => _do_ancestorOrSelfHash
	| 'ancestor-or-self::' 	keyname							action => _do_ancestorOrSelfNamed
	| 'ancestor-or-self::' 	UINT						  	action => _do_ancestorOrSelfIndexedOrNamed
	| 'ancestor-or-self::[' UINT ']'				  	action => _do_ancestorOrSelfIndexed
	| 'descendant::*'														action => _do_descendant
	| 'descendant::[*]'													action => _do_descendantArray
	| 'descendant::{*}'													action => _do_descendantHash
	| 'descendant::' keyname										action => _do_descendantNamed
	| 'descendant::' UINT												action => _do_descendantIndexedOrNamed
	| 'descendant::[' UINT ']'									action => _do_descendantIndexed
	| 'descendant-or-self::*'										action => _do_descendantOrSelf
	| 'descendant-or-self::[*]'									action => _do_descendantOrSelfArray
	| 'descendant-or-self::{*}'									action => _do_descendantOrSelfHash
	| 'descendant-or-self::' keyname						action => _do_descendantOrSelfNamed
	| 'descendant-or-self::' UINT								action => _do_descendantOrSelfIndexedOrNamed
	| 'descendant-or-self::[' UINT ']'					action => _do_descendantOrSelfIndexed
	| 'preceding-sibling::*' 										action => _do_precedingSibling
	| 'preceding-sibling::[*]' 									action => _do_precedingSiblingArray
	| 'preceding-sibling::{*}' 									action => _do_precedingSiblingHash
	| 'preceding-sibling::' keyname 						action => _do_precedingSiblingNamed
	| 'preceding-sibling::' UINT 								action => _do_precedingSiblingIndexedOrNamed
	| 'preceding-sibling::[' UINT ']'						action => _do_precedingSiblingIndexed
	| 'following-sibling::*' 										action => _do_followingSibling
	| 'following-sibling::[*]' 									action => _do_followingSiblingArray
	| 'following-sibling::{*}' 									action => _do_followingSiblingHash
	| 'following-sibling::' keyname 						action => _do_followingSiblingNamed
	| 'following-sibling::' UINT 								action => _do_followingSiblingIndexedOrNamed
	| 'following-sibling::[' UINT ']'						action => _do_followingSiblingIndexed

IndexExprs ::= IndexExpr+ 			separator => <comma>

IndexExpr ::=
	IntExpr																			action => _do_index_single
	| rangeExpr																	action => _do_arg1

rangeExpr ::= 
	IntExpr '..' IntExpr 												action => _do_index_range
	|IntExpr '..' 															action => _do_startRange
	| '..' IntExpr															action => _do_endRange

Filter ::= 
	IndexFilter
	| LogicalFilter
	| Filter Filter 														action => _do_mergeFilters

LogicalFilter ::= 	
	'[' LogicalExpr ']' 												action => _do_boolean_filter

IndexFilter ::= 	
	'[' IndexExprs ']'													action => _do_index_filter


IntExpr ::=
  WS ArithmeticIntExpr WS											action => _do_arg2

 ArithmeticIntExpr ::=
 	INT 																				action => _do_arg1
	| IntegerFunction														action => _do_arg1
	| '(' IntExpr ')' 													action => _do_group
	|| '-' ArithmeticIntExpr 										action => _do_unaryOperator
	 | '+' ArithmeticIntExpr 										action => _do_unaryOperator
	|| IntExpr '*' IntExpr  										action => _do_binaryOperation
	 | IntExpr 'div' IntExpr 										action => _do_binaryOperation
#	 | IntExpr ' /' IntExpr 	 									action => _do_binaryOperation 
#	 | IntExpr '/ ' IntExpr 										action => _do_binaryOperation 
	 | IntExpr '%' IntExpr  										action => _do_binaryOperation
	|| IntExpr '+' IntExpr  										action => _do_binaryOperation
	 | IntExpr '-' IntExpr  										action => _do_binaryOperation


NumericExpr ::=
  WS ArithmeticExpr WS 												action => _do_arg2

ArithmeticExpr ::=
	NUMBER 																			action => _do_arg1
	|| PredPathExpr															action => _do_getValueOperator
	| NumericFunction														action => _do_arg1
	| '(' NumericExpr ')' 											action => _do_group
	|| '-' ArithmeticExpr 											action => _do_unaryOperator
	 | '+' ArithmeticExpr 											action => _do_unaryOperator
	|| NumericExpr '*' NumericExpr							action => _do_binaryOperation
	 | NumericExpr 'div' NumericExpr						action => _do_binaryOperation
#	 | NumericExpr ' /' NumericExpr							action => _do_binaryOperation
#	 | NumericExpr '/ ' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '%' NumericExpr							action => _do_binaryOperation
	|| NumericExpr '+' NumericExpr							action => _do_binaryOperation
	 | NumericExpr '-' NumericExpr							action => _do_binaryOperation

LogicalExpr ::=
	WS LogicalFunction WS												action => _do_arg2
	|| WS compareExpr WS												action => _do_arg2

compareExpr ::=	
	PredPathExpr																action => _do_exists
	|| AnyTypeExpr '<' AnyTypeExpr							action => _do_binaryOperation
	 | AnyTypeExpr '<=' AnyTypeExpr							action => _do_binaryOperation
	 | AnyTypeExpr '>' AnyTypeExpr							action => _do_binaryOperation
	 | AnyTypeExpr '>=' AnyTypeExpr							action => _do_binaryOperation
	 | StringExpr 'lt' StringExpr								action => _do_binaryOperation
	 | StringExpr 'le' StringExpr								action => _do_binaryOperation
	 | StringExpr 'gt' StringExpr								action => _do_binaryOperation
	 | StringExpr 'ge' StringExpr								action => _do_binaryOperation
	 | StringExpr '~' RegularExpr								action => _do_binaryOperation
	 | StringExpr '!~' RegularExpr							action => _do_binaryOperation
	 | NumericExpr '===' NumericExpr						action => _do_binaryOperation
	 | NumericExpr '!==' NumericExpr						action => _do_binaryOperation
	 | AnyTypeExpr '==' AnyTypeExpr							action => _do_binaryOperation 
	 | AnyTypeExpr '=' AnyTypeExpr							action => _do_binaryOperation #to be xpath compatible
	 | AnyTypeExpr '!=' AnyTypeExpr							action => _do_binaryOperation
	 | StringExpr 'eq' StringExpr								action => _do_binaryOperation
	 | StringExpr 'ne' StringExpr								action => _do_binaryOperation
	|| LogicalExpr 'and' LogicalExpr						action => _do_binaryOperation
	|| LogicalExpr 'or' LogicalExpr							action => _do_binaryOperation


AnyTypeExpr ::=
	WS allTypeExp WS 														action => _do_arg2	

allTypeExp ::=
	NumericExpr 																action => _do_arg1
	|StringExpr 																action => _do_arg1					
  || PredPathExpr 														action => _do_getValueOperator 


StringExpr ::=
	WS allStringsExp WS 													action => _do_arg2

allStringsExp ::=
	STRING 			 																action => _do_arg1
 	| StringFunction														action => _do_arg1
 	| PredPathExpr															action => _do_getValueOperator
 	|| StringExpr '||' StringExpr  							action => _do_binaryOperation


RegularExpr ::= 
	WS STRING	WS																action => _do_re

LogicalFunction ::=
	'not' '(' LogicalExpr ')'			 							action => _do_func
	| 'isRef' '('  OptionalPathArgs  ')'			 	action => _do_func
	| 'isScalar' '(' OptionalPathArgs ')'			 	action => _do_func
	| 'isArray' '(' OptionalPathArgs ')'			 	action => _do_func
	| 'isHash' '(' OptionalPathArgs ')'			 		action => _do_func
	| 'isCode' '(' OptionalPathArgs ')'					action => _do_func

StringFunction ::=
	NameFunction																action => _do_arg1
	| ValueFunction															action => _do_arg1

NameFunction ::= 
	'name' '(' OptionalPathArgs ')'				 			action => _do_func

OptionalPathArgs ::= 
	RequiredPathArgs						  							action => _do_arg1
	| EMPTY																			action => _do_arg1

RequiredPathArgs ::=
	WS PathExpr WS						  								action => _do_arg2

EMPTY ::= 

ValueFunction ::= 
	'value' '(' OptionalPathArgs ')'				 		action => _do_func

CountFunction ::= 
	'count' '(' RequiredPathArgs ')'				 		action => _do_func

LastFunction ::= 
	'last' '(' OptionalPathArgs ')'					 		action => _do_func

PositionFunction ::= 
	'position' '(' OptionalPathArgs ')'			 		action => _do_func

SumFunction ::= 
	'sum' '(' RequiredPathArgs ')'				 			action => _do_func

SumProductFunction ::= 
	'sumproduct' '(' RequiredPathArgs ',' RequiredPathArgs ')'	action => _do_funcw2args

NumericFunction ::=
	IntegerFunction															action => _do_arg1
	|ValueFunction															action => _do_arg1
	|SumFunction																action => _do_arg1
	|SumProductFunction													action => _do_arg1

IntegerFunction ::=
	CountFunction																action => _do_arg1
	|LastFunction																action => _do_arg1
	|PositionFunction														action => _do_arg1

ListFunction ::=
	'names' '(' OptionalPathArgs ')'    		 		action => _do_func
	| 'values' '(' OptionalPathArgs ')'    		 	action => _do_func
	| 'lasts' '(' OptionalPathArgs ')'    		 	action => _do_func
	| 'positions' '(' OptionalPathArgs ')'    	action => _do_func


 NUMBER ::= 
 	unumber 																		action => _do_arg1
 	| '-' unumber 															action => _do_join
 	| '+' unumber 															action => _do_join

unumber	
	~ uint
	| uint frac
	| uint exp
	| uint frac exp
	| frac
	| frac exp
 
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
	~ ['] single_quoted_chars [']

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

keyname ::= 
	keyword																			action => _do_token
	| STRING            												action => _do_arg1
	| curly_delimited_string   									action => _do_curly_delimited_string

curly_delimited_string
	~ '{' curly_delimited_chars '}'

curly_delimited_chars
	~ curly_delimited_char*

curly_delimited_char
	~ [^}{]
	| '\'	'{'
	| '\'	'}'

keyword 
	~ ID

ID 
	~ token
	| token ':' token      #to allow replication of xml tags names with namespaces

token 								#must have at least one non digit 
	~ notreserved
	| token [\d] 
	| [\d] token

notreserved 
	~ [^\d:./*,'"|\s\]\[\(\)\{\}\\+-<>=!]+


# :discard 
# 	~ WS

WS ::= 
	whitespace
	|EMPTY

whitespace
	~ [\s]+

comma 
	~ ','

END_OF_SOURCE
});

sub _do_arg1{ return $_[1]};
sub _do_arg2{ return $_[2]};

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
sub _do_curly_delimited_string{
    my $s = $_[1];
    $s =~ s/#([0-9]+)#/chr $1/ge; #recovery utf8 character 
    $s =~ s/^{|}$//g;
    $s =~ s/\\{/{/g;
    $s =~ s/\\}/}/g;
    return $s;	
}
sub _do_re{
	my $re = $_[2];
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
sub _do_getValueOperator{
	return {values => $_[1]}
}
sub _do_binaryOperation{
	my $oper = 	[$_[2]];
	$oper =~ s/^\s+|\s+$//g;
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
sub _do_relativePath2{
	return [{relative => 1, path => $_[2]}];
}
sub _do_boolean_filter{ 
	return {boolean => $_[2]}
};
sub _do_mergeFilters{
	my ($filters1, $filters2) = @_[1,2];
	my @filters = (@$filters1, @$filters2);
	return \@filters; 
}
sub _do_index_filter{
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
sub  _do_vlen{
	return {
			slashslash => $_[1],
			subpath => $_[2]
	};
}
sub _do_descendant{
	return {descendant => $_[1]};	
}
sub _do_descendantArray{
	return {descendantArray => $_[1]};	
}
sub _do_descendantHash{
	return {descendantHash => $_[1]};	
}
sub _do_descendantNamed{
	return {descendantNamed => $_[2]};	
}
sub _do_descendantIndexed{
	return {descendantIndexed => $_[2]};	
}
sub _do_descendantIndexedOrNamed{
	return {descendantIndexedOrNamed => $_[2]};	
}
sub _do_descendantOrSelf{
	return {descendantOrSelf => $_[1]};	
}
sub _do_descendantOrSelfArray{
	return {descendantOrSelfArray => $_[1]};	
}
sub _do_descendantOrSelfHash{
	return {descendantOrSelfHash => $_[1]};	
}
sub _do_descendantOrSelfNamed{
	return {descendantOrSelfNamed => $_[2]};	
}
sub _do_descendantOrSelfIndexed{
	return {descendantOrSelfIndexed => $_[2]};	
}
sub _do_descendantOrSelfIndexedOrNamed{
	return {descendantOrSelfIndexedOrNamed => $_[2]};	
}
sub _do_precedingSibling{
	return {precedingSibling => $_[1]};	
}
sub _do_precedingSiblingArray{
	return {precedingSiblingArray => $_[1]};	
}
sub _do_precedingSiblingHash{
	return {precedingSiblingHash => $_[1]};	
}
sub _do_precedingSiblingNamed{
	return {precedingSiblingNamed => $_[2]};	
}
sub _do_precedingSiblingIndexed{
	return {precedingSiblingIndexed => $_[2]};	
}
sub _do_precedingSiblingIndexedOrNamed{
	return {precedingSiblingIndexedOrNamed => $_[2]};	
}
sub _do_followingSibling{
	return {followingSibling => $_[1]};	
}
sub _do_followingSiblingArray{
	return {followingSiblingArray => $_[1]};	
}
sub _do_followingSiblingHash{
	return {followingSiblingHash => $_[1]};	
}
sub _do_followingSiblingNamed{
	return {followingSiblingNamed => $_[2]};	
}
sub _do_followingSiblingIndexed{
	return {followingSiblingIndexed => $_[2]};	
}
sub _do_followingSiblingIndexedOrNamed{
	return {followingSiblingIndexedOrNamed => $_[2]};	
}
sub _do_child{
	return {child => $_[1]};
}
sub _do_childArray{
	return {childArray => $_[1]};
}
sub _do_childHash{
	return {childHash => $_[1]};
}
sub _do_keyname{
	return {childNamed => $_[1]};	
}
sub _do_array_index{
	return {childIndexed => $_[2]}	
}
sub _do_array_hash_index{
	return {childIndesxedOrNamed => $_[1]}	
}
sub _do_childNamed{
	return {childNamed => $_[2]};
}
sub _do_childIndexed{
	return {childIndexed => $_[2]};
}
sub _do_childIndexedOrNamed{
	return {childIndesxedOrNamed => $_[2]};
}
sub _do_self{
	return {self =>  $_[1]};	
}
sub _do_selfArray{
	return {selfArray =>  $_[1]};	
}
sub _do_selfHash{
	return {selfHash =>  $_[1]};	
}
sub _do_selfNamed{
	return { selfNamed => $_[2]};	
}
sub _do_selfIndexedOrNamed{
	return { selfIndexedOrNamed => $_[2]};	
}
sub _do_selfIndexed{
	return { selfIndexed => $_[2]};	
}
sub _do_parent{
	return {parent => $_[1]};	
}
sub _do_parentArray{
	return {parentArray => $_[1]};	
}
sub _do_parentHash{
	return {parentHash => $_[1]};	
}
sub _do_parentNamed{
	return {parentNamed => $_[2]};
}
sub _do_parentIndexed{
	return {parentIndexed => $_[2]};
}
sub _do_parentIndexedOrNamed{
	return {parentIndexedOrNamed => $_[2]};
}
sub _do_ancestor{
	return {ancestor => $_[1]};
}
sub _do_ancestorArray{
	return {ancestorArray => $_[1]};
}
sub _do_ancestorHash{
	return {ancestorHash => $_[1]};
}
sub _do_ancestorNamed{
	return {ancestorNamed => $_[2]};	
}
sub _do_ancestorIndexed{
	return {ancestorIndexed => $_[2]};	
}
sub _do_ancestorIndexedOrNamed{
	return {ancestorIndexedOrNamed => $_[2]};	
}
sub _do_ancestorOrSelf{
	return {ancestorOrSelf => $_[1]}	
}
sub _do_ancestorOrSelfArray{
	return {ancestorOrSelfArray => $_[1]}	
}
sub _do_ancestorOrSelfHash{
	return {ancestorOrSelfHash => $_[1]}	
}
sub _do_ancestorOrSelfNamed{
	return {ancestorOrSelfNamed => $_[2]}		
}
sub _do_ancestorOrSelfIndexed{
	return {ancestorOrSelfIndexed => $_[2]}		
}
sub _do_ancestorOrSelfIndexedOrNamed{
	return {ancestorOrSelfIndexedOrNamed => $_[2]}		
}
#############################end of rules################################

my @context = ();
sub _names{
			return map {$_->{name}} _getSubObjectsOrCurrent(@_);
}
sub _values{
	#print 'Values arg = ', Dumper \@_;
	return map {${$_->{data}}} _getSubObjectsOrCurrent(@_);
}
sub _positions{
	my @r = _getSubObjectsOrCurrent(@_);
	return map {$_->{pos}} @r;			
}
sub _lasts{
	my @r = _getSubObjectsOrCurrent(@_);
	return map {$_->{size}} @r;	
}

no warnings qw{uninitialized numeric};

my $operatorBy = {
	'=' => sub($$){
		return _logicalOper(sub {$_[0] == $_[1]}, $_[0], $_[1]);
	},
	'==' => sub($$){
		return _logicalOper(sub {$_[0] == $_[1]}, $_[0], $_[1]);
	},
	'!=' => sub($$){
		return _logicalOper(sub {$_[0] != $_[1]}, $_[0], $_[1]);
	},
	'eq' => sub($$){
		return _logicalOper(sub {$_[0] eq $_[1]}, $_[0], $_[1]);
	},
	'ne' => sub($$){
		return _logicalOper(sub {$_[0] ne $_[1]}, $_[0], $_[1]);
	},
	'===' => sub($$){
		return _logicalOper(sub {
			looks_like_number($_[0])
			and looks_like_number($_[1])
			and $_[0] == $_[1]
		}, $_[0], $_[1]);
	},
	'!==' => sub($$){
		return _logicalOper(sub {
			$_[0] != $_[1]
		}, $_[0], $_[1]);
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
	'*' => sub($$;@){
		return _naryOper(sub {$_[0] * $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'div' => sub($$;@){
		return _naryOper(sub {
			my $r = eval {$_[0] / $_[1]};
			carp qq|Division problems\n$@| if $@;
			return $r;
		}, $_[0], $_[1], @_[2..$#_]);
	},
	'/' => sub($$;@){
		return _naryOper(sub {
			my $r = eval {$_[0] / $_[1]};
			carp qq|Division problems\n$@| if $@;
			return $r;
		}, $_[1], @_[2..$#_]);
	},
	'+' => sub($$;@){
		return _naryOper(sub {$_[0] + $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'-' => sub($$;@){
		return _naryOper(sub {$_[0] - $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'%' => sub($$;@){
		return _naryOper(sub {$_[0] % $_[1]}, $_[0], $_[1], @_[2..$#_]);
	},
	'||' => sub{
		return _naryOper(sub {$_[0] . $_[1]}, $_[0], $_[1], @_[2..$#_])
	},
	names => \&_names,
	values => \&_values,
	positions => \&_positions,
	lasts => \&_lasts,
	name => sub {
		return (_names(@_))[0] // q||;
	},
	value => sub(){
		return (_values(@_))[0] // q||;
	},
	position => sub{
		my @r = _positions(@_);
		return $r[$#r] // 0;		
	},
	last => sub{
		my @r = _lasts(@_);
		return $r[$#r] // 0;
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
sub _operation($){
	my $operData = $_[0];
	return undef unless defined $operData and ref $operData eq q|HASH|;
	my %types = (
		oper => sub{
			my ($oper, @args) = @{$operData->{oper}};
			#print "oper=$oper";
			#my $oper = $params[0];
			return undef unless defined $oper and exists $operatorBy->{$oper};
			#my @args = @params[1..$#params];
			return $operatorBy->{$oper}->(@args);  			
		},
		values =>sub{
			my @r = $operatorBy->{values}->($operData->{values});
			return @r;
		}
	);
	#print 'operdata = ', Dumper $operData;
	my @r = map {$types{$_}->()} grep {exists $types{$_}} keys %$operData;
	return @r if wantarray();
	return $r[0];
}
sub _naryOper(&$$;@){
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
		#print "x=", Dumper $x;
		#print "y=", Dumper $y;
		my @x = ($x);
		my @y = ($y);
		@x = _operation($x) if ref $x and ref $x ne q|Regexp|;
		@y = _operation($y) if ref $y and ref $y ne q|Regexp|;
		#my @r = eval {};
		#warn qq|Warning: $@| if $@;
		foreach my $x (@x){
			foreach my $y (@y){
				return 1 if $oper->($x,$y)
			}	
		}
		return 0;
		#return $oper->($x,$y);
}


sub _evaluate{
	my $x = $_[0];
	return $x unless ref $x eq q|HASH| and exists $x->{oper};
	return _operation($x);
}
sub getStruct{
	my ($context, $subpath) = @_;
	return ($context) unless defined $subpath;
	push @context, $context;
	my @r = _getObjectSubset(${$context->{data}}, $subpath);
	pop @context;
	return @r; 
}
my %filterType = (
	boolean => sub {
		return  _operation($_[0]);
	}
	, indexes => sub{
		sub computeIndex{
			my $index = 0 + _evaluate($_[0]);
			$index += 1 + $context[$#context]->{size} if $index < 0;
			return $index;
		}
		my %indexType = (
			index => sub{
				return $context[$#context]->{pos} == computeIndex($_[0]);
			}
			, range => sub{
				#print 'range', Dumper $_[0];
				my $pos = $context[$#context]->{pos};
				my ($start, $end) = map {computeIndex($_)} @{$_[0]};
				return $pos >= $start && $pos <= $end;
			}
			, from => sub{
				#print 'from', Dumper $_[0];
				return $context[$#context]->{pos} >= computeIndex($_[0]);				
			}
			, to => sub{
				#print 'to', Dumper $_[0];
				return $context[$#context]->{pos} <= computeIndex($_[0]);				
			}
		);
		#print 'indexes filter ',Dumper @_;
		my $indexes = $_[0];
		foreach my $index (@$indexes){
			#print 'evaluate', Dumper $index;
			return 1 if (map {$indexType{$_}->($index->{$_})} grep {exists $indexType{$_}} keys %$index)[0]; 
		}
		return 0;
	}	
);
sub _filter{
	my ($context,$filter) = @_;
	#print 'validate -> ', Dumper \@_;
	return 1 unless defined $filter and ref $filter eq q|HASH|;  #just in case
	push @context, $context;
	my ($r) = map {$filterType{$_}->($filter->{$_})} grep {exists $filterType{$_}} keys %$filter;
	pop @context;
	return $r;	
}
sub _getFilteredKeys{
	my ($data,$filter,@keys) = @_;
	$filter //= [];
	my $order = $context[$#context]->{order} // q||;
	my $size = scalar @keys;

	my @keyIndex = map{{
		name => $keys[$_], 
		type => q|HASH|, 
		data  => \$data->{$keys[$_]}, 
		order => qq|$order/$keys[$_]|, 
		size => scalar @keys
	}} 0..$#keys;
	foreach my $filter (@$filter){
		my $pos = 1;
		$size = scalar @keyIndex;
		@keyIndex = grep {_filter(
					$_
					,$filter
		)} map {@{$_}{qw|pos size|} = ($pos++, $size); $_} @keyIndex ;
	}

	my $pos = 1;
	$size = scalar @keyIndex;
	return map {@{$_}{qw|pos size|} = ($pos++, $size); $_} @keyIndex	
}
sub _getFilteredIndexes{
	my ($data,$filter,@indexes) = @_;
	$filter //= [];
	my $order = $context[$#context]->{order} // q||;
	my $size = scalar @indexes;
	my $large = 1;
	{	use integer;	my $n = $size; $large++ while($n /= 10); } #a scope to do integer operations;

	my @r = map {{															#init result array 	
		name => $_, 
		type => q|ARRAY|, 
		data  => \$data->[$_], 
		order => qq|$order/|.sprintf("%0*u",$large,$_), 
		size => $size
	}} @indexes;
	
	foreach my $filter (@$filter){
		my $pos = 1;
		$size = scalar @r;
		@r = grep {_filter(												#filter out from result
					$_				
					,$filter
		)} map {@{$_}{qw|pos size|} = ($pos++, $size); $_} @r ;
	}

	my $pos = 1;
	$size = scalar @r;
	return map{	@{$_}{qw|pos size|} = ($pos++, $size); $_} @r; 			#compute final positions in context
}
sub _anyChildType{
	my ($type,$name,$data,$subpath,$filter) = @_;
	my %filterByDataType = (
			HASH => sub{
				return () if defined $type and $type ne q|HASH|;
				my @keys = keys %$data;
				@keys = grep {$_ eq $name} @keys if defined $name;
				return _getFilteredKeys($data,$filter, sort @keys);
			}
			, ARRAY => sub{
				return () if defined $type and $type ne q|ARRAY|;
				my @indexes = 0..$#$data;
				@indexes = grep {$_ == $name} @indexes if defined $name;
				return _getFilteredIndexes($data,$filter, @indexes);
			}
	);
	return 
		map {getStruct($_, $subpath)} 
		map { $filterByDataType{$_}->()} 
		grep {exists $filterByDataType{$_}} 
		(ref $data);
}
sub _descendant{
	my ($data,$path) = @_;
	#print 'context', Dumper \@context;
	my @r = _getObjectSubset($data,$path);	
	my $order = $context[$#context]->{order} // q||;
	#print "order = $order";
	if (ref $data eq q|HASH|){
			my @keys = sort keys %$data;
			foreach (@keys){
				push @context, {name => $_, type => q|HASH|, data  => \$data->{$_}, order => qq|$order/$_|, pos =>1, size => scalar @keys };
				push @r, _descendant($data->{$_}, $path);
				pop @context;
			}
	}
	if (ref $data eq q|ARRAY|){
			foreach (0 .. $#$data){
				push @context, {name => $_, type => q|ARRAY|, data  => \$data->[$_], order =>  qq|$order/$_|, pos=> 1, size => scalar @$data};
				push @r, _descendant($data->[$_], $path);
				pop @context;
			}
	} 
	return @r;
}
sub _getDescendants{
	my($descendants,$subpath) = @_;
	my @r=();
	foreach (0..$#$descendants){
			if (defined $descendants->[$_]){						#only if descendants was selected
					my $last = $#context;
					#print "descendant of $_", Dumper $descendants->[$_];
					#print "subpath", Dumper $subpath;
					push @context, @{$descendants->[$_]};
					push @r, defined $subpath ?
						_getObjectSubset(${$context[$#context]->{data}}, $subpath)
						: ($context[$#context]);
					$#context = $last;						
			}
	}
	return @r;
}

sub _getDescContexts{
		my (@context) = @_;
		my @r = ();
		my $order = $context[$#context]->{order} // q||;
		my $data = ${$context[$#context]->{data}};
		my $pos = 1;
		if (ref $data eq q|HASH|){
				my @keys = sort keys %$data;
				foreach (@keys){
					push @r, _getDescContexts(@context, {name => $_, type => q|HASH|, data  => \$data->{$_}, order => qq|$order/$_|, pos =>$pos++, size => scalar @keys });
				}
		}
		if (ref $data eq q|ARRAY|){
				foreach (0 .. $#$data){
					push @r, _getDescContexts(@context, {name => $_, type => q|ARRAY|, data  => \$data->[$_], order =>  qq|$order/$_|, pos => $pos++, size => scalar @$data});
				}
		}
		return (\@context, @r);
}

sub _filterOutDescendants{
	my ($filters,$size,$descendants) = @_;
	$filters //= [];

	
	#print 'descendants', scalar @$descendants, Dumper \@$descendants;
	foreach my $filter (@$filters){
		my $pos = 1;
		my $cnt = 0;
		foreach my $k (0..$#$descendants){
			if (defined $descendants->[$k]){
				my $last = $#context;
				push @context, @{$descendants->[$k]};
				my ($s,$p) = @{$context[$#context]}{qw|size pos|};
				@{$context[$#context]}{qw|size pos|} = ($size,$pos++);	
				$cnt++, undef $descendants->[$k] if !_filter($context[$#context],$filter);
				@{$context[$#context]}{qw|size pos|} = ($s,$p);	
				$#context = $last;
			}
		}
		$size -= $cnt;
	}
	#print 'Selected descendants', scalar @$descendants, Dumper \@$descendants;
	return $descendants;	
}
sub _getDescendantsByTypeAndName{
		my ($type, $name, $subpath,$filter,$self) = @_;
		my $descendants = [_getDescContexts($context[$#context])];
		shift @$descendants unless $self;
		$descendants = [grep {$_->[$#$_]->{name} eq $name} @$descendants] if defined $name;
		$descendants = [grep {$_->[$#$_]->{type} eq $type} @$descendants] if defined $type;
		shift @{$descendants->[$_]} foreach (0..$#$descendants); #remove the current context from context list.
		my $size = scalar @$descendants;
		return _getDescendants(_filterOutDescendants($filter,$size,$descendants), $subpath);
}

sub _getAncestorsOrSelf{ 
	my ($ancestors,$subpath) = @_; 
	my @tmp = ();
	my @r;
	foreach (0..$#$ancestors){
			if (defined $ancestors->[$_]){						#only if ancestor was selected
					push @r, defined $subpath ?
						_getObjectSubset(${$context[$#context]->{data}}, $subpath)
						: ($context[$#context])						
			}
			push @tmp, pop @context;
	}
	push @context, pop @tmp while(scalar @tmp > 0); #repo @context
	return @r;
}
		# foreach (0..$#$ancestors){	#pre filter ancestors with named ones, only!
		# 	$size--, undef $ancestors->[$_] if $context[$_]->{name} ne $name;
		# }
sub _filterOutAncestorsOrSelf{
	my($type,$name,$filter,$ancestorsIndex) = @_;
	$filter //= [];

	#as array of flags. Each position flags a correpondent ancestor
	#my @ancestorsIndex = map {1} (0..$#context); 
	

	#filter out ancestors with a different name!
	map {	
		undef $ancestorsIndex->[$_] if $context[$#context - $_]->{name} ne $name;
	} 0..$#$ancestorsIndex if defined $name;

	#filter out ancestors of a different type!
	map {	
		undef $ancestorsIndex->[$_] if $context[$#context - $_]->{type} ne $type;#Não se devia decrementar duplamente
	} 0..$#$ancestorsIndex if defined $type;
	
	my $size = 0;
	map {$size++ if defined $_} @$ancestorsIndex;

	foreach my $filter (@$filter){
		my $pos = 1;
		my @tmp = ();
		my $cnt = 0;
		foreach my $k (0..$#$ancestorsIndex){
			if (defined $ancestorsIndex->[$k]){
				my ($s,$p) = @{$context[$#context]}{qw|size pos|};
		 		@{$context[$#context]}{qw|size pos|} = ($size,$pos++);		
				$cnt++, undef $ancestorsIndex->[$k] if !_filter($context[$#context],$filter);
				@{$context[$#context]}{qw|size pos|} = ($s,$p);
			}		
			push @tmp, pop @context;
		}
		push @context, pop @tmp while(scalar @tmp > 0); #repo @context
		$size -= $cnt; 				#adjust the group's size;
	}
	return $ancestorsIndex;
} 
sub _filterOutSiblings{
	my ($type, $name, $subpath,$filter,$direction) = @_;
	my $mySelf = $context[$#context]->{data};
	my $context = pop @context;
	my $data = ${$context[$#context]->{data}};

	my %filterByDataType = (
			HASH => sub{
				my @keys = sort keys %$data;
				my $cnt = $#keys;
				$cnt-- while($cnt >= 0 and \$data->{$keys[$cnt]} != $mySelf);	
				my @siblings = do {
					if ($direction eq q|preceding|){
						$#keys = $cnt-1;
						reverse @keys[0 .. $cnt-1];
					}elsif($direction eq q|following|){
						@keys[$cnt+1 .. $#keys]
					}
				};
				@siblings = grep {$_ eq $name} @siblings if defined $name;
				@siblings = grep {q|HASH| eq $type} @siblings if defined $type;
				return _getFilteredKeys($data,$filter, @siblings);
			}
			, ARRAY => sub{
				my $cnt = $#$data;
				$cnt-- while($cnt >= 0 and \$data->[$cnt] != $mySelf);
				my @siblings = do {
					if ($direction eq q|preceding|){
						reverse 0..$cnt-1
					}elsif($direction eq q|following|){
						$cnt+1 .. $#$data		
					}
				};
				@siblings = grep {$_ eq $name} @siblings if defined $name;
				@siblings = grep {q|ARRAY| eq $type} @siblings if defined $type;
				return _getFilteredIndexes($data,$filter, @siblings);
			}
	);
	my @r = 
		map {getStruct($_, $subpath)} 
		map { $filterByDataType{$_}->()} 
		grep {exists $filterByDataType{$_}} 
		(ref $data);
	push @context, $context;
	return @r;
}

my $dispatcher = {
	self => sub{
		my (undef, undef, $subpath,$filter) = @_;
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0]), $subpath);
	},
	selfArray => sub{
		my (undef, undef, $subpath,$filter) = @_;
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0]), $subpath);
	},
	selfHash => sub {
		my (undef, undef, $subpath,$filter) = @_;
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0]), $subpath);
	},
	selfNamed => sub{
		my (undef, $name, $subpath,$filter) = @_;
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, $name, $filter, [0]), $subpath);
	},
	selfIndexed => sub{
		my (undef, $index, $subpath,$filter) = @_;
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, $index, $filter, [0]), $subpath);
	},
	selfIndexedOrNamed => sub{
		my (undef, $index, $subpath,$filter) = @_;
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, $index, $filter, [0]), $subpath);
	},
	parent => sub{
		my (undef, undef, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0]), $subpath);
		push @context, $current;
		return @r;
	},
	parentArray => sub{
		my (undef, undef, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0]), $subpath);
		push @context, $current;
		return @r;
	},
	parentHash => sub{
		my (undef, undef, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0]), $subpath);
		push @context, $current;
		return @r;
	},
	parentNamed => sub{
		my (undef, $name, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, $name, $filter, [0]), $subpath);
		push @context, $current;
		return @r;
	},
	parentIndexed => sub{
		my (undef, $index, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, $index, $filter, [0]), $subpath);
		push @context, $current;
		return @r;
	},
	parentIndexedOrNamed => sub{
		my (undef, $index, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, $index, $filter, [0]), $subpath);
		push @context, $current;
		return @r;
	},
	ancestor => sub{
		my (undef, undef, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0..$#context]), $subpath);
		push @context, $current;
		return @r;
	},
	ancestorArray => sub{
		my (undef, undef, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0..$#context]), $subpath);
		push @context, $current;
		return @r;
	},
	ancestorHash => sub{
		my (undef, undef, $subpath,$filter) = @_;

		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0..$#context]), $subpath);
		push @context, $current;
		return @r;
	},
	ancestorNamed => sub{
		my (undef, $name, $subpath,$filter) = @_;
	
		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, $name, $filter, [0..$#context]), $subpath);
		push @context, $current;
		return @r;
	},
	ancestorIndexed => sub{
		my (undef, $index, $subpath,$filter) = @_;
	
		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, $index, $filter, [0..$#context]), $subpath);
		push @context, $current;
		return @r;
	},
	ancestorIndexedOrNamed => sub{
		my (undef, $index, $subpath,$filter) = @_;
	
		my $current = pop @context;
		my @r = _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, $index, $filter, [0..$#context]), $subpath);
		push @context, $current;
		return @r;
	},
	ancestorOrSelf => sub{
		my (undef, undef, $subpath,$filter) = @_;
	
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef, undef, $filter, [0..$#context]), $subpath);
	}, 
	ancestorOrSelfArray => sub{
		my (undef, undef, $subpath,$filter) = @_;
	
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|, undef, $filter, [0..$#context]), $subpath);
	}, 
	ancestorOrSelfHash => sub{
		my (undef, undef, $subpath,$filter) = @_;
	
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|, undef, $filter, [0..$#context]), $subpath);
	}, 
	ancestorOrSelfNamed => sub{
		my (undef, $name, $subpath,$filter) = @_;
	
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|HASH|,$name,$filter, [0..$#context]), $subpath);
	}, 
	ancestorOrSelfIndexed => sub{
		my (undef, $index, $subpath,$filter) = @_;
	
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(q|ARRAY|,$index,$filter, [0..$#context]), $subpath);
	}, 
	ancestorOrSelfIndexedOrNamed => sub{
		my (undef, $index, $subpath,$filter) = @_;
	
		return _getAncestorsOrSelf(_filterOutAncestorsOrSelf(undef,$index,$filter,[0..$#context]), $subpath);
	}, 
	child => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _anyChildType(undef,undef,$data,$subpath,$filter);		
	},
	childArray => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _anyChildType(q|ARRAY|,undef,$data,$subpath,$filter);		
	},
	childHash => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _anyChildType(q|HASH|,undef,$data,$subpath,$filter);		
	},
	childNamed => sub{
		my ($data, $name, $subpath,$filter) = @_;
		return _anyChildType(q|HASH|,$name,$data,$subpath,$filter);		
	},
	childIndexed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _anyChildType(q|ARRAY|,$index,$data,$subpath,$filter);		
	},
	childIndesxedOrNamed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _anyChildType(undef,$index,$data,$subpath,$filter);		
	},
	descendant => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(undef,undef,$subpath,$filter)
	},
	descendantArray => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(q|ARRAY|,undef,$subpath,$filter)
	},
	descendantHash => sub{
		my ($data, undef, $subpath,$filter) = @_;
		print "AQUI";
		return _getDescendantsByTypeAndName(q|HASH|,undef,$subpath,$filter)
	},
	descendantNamed => sub{
		my ($data, $name, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(q|HASH|,$name,$subpath,$filter)
	},
	descendantIndexed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(q|ARRAY|,$index,$subpath,$filter)
	},
	descendantIndexedOrNamed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(undef,$index,$subpath,$filter)
	},
	descendantOrSelf => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(undef,undef,$subpath,$filter,1)
	},
	descendantOrSelfArray => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(q|ARRAY|,undef,$subpath,$filter,1)
	},
	descendantOrSelfHash => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(q|HASH|,undef,$subpath,$filter,1)
	},
	descendantOrSelfNamed => sub{
		my ($data, $name, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(q|HASH|,$name,$subpath,$filter,1)
	},
	descendantOrSelfIndexed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(q|ARRAY|,$index,$subpath,$filter,1)
	},
	descendantOrSelfIndexedOrNamed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _getDescendantsByTypeAndName(undef,$index,$subpath,$filter,1)
	},
	precedingSibling => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _filterOutSiblings(undef,undef,$subpath, $filter,q|preceding|)		
	},
	precedingSiblingArray => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _filterOutSiblings(q|ARRAY|,undef,$subpath, $filter,q|preceding|)		
	},
	precedingSiblingHash => sub{
		my ($data, undef, $subpath,$filter) = @_;
		_filterOutSiblings(q|HASH|,undef,$subpath, $filter,q|preceding|)		
	},
	precedingSiblingNamed => sub{
		my ($data, $name, $subpath,$filter) = @_;
		return _filterOutSiblings(q|HASH|,$name,$subpath, $filter,q|preceding|)		
	},
	precedingSiblingIndexed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _filterOutSiblings(q|ARRAY|,$index,$subpath, $filter,q|preceding|)		
	},
	precedingSiblingIndexedOrNamed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _filterOutSiblings(undef,$index,$subpath, $filter,q|preceding|)		
	},
	followingSibling => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _filterOutSiblings(undef,undef,$subpath, $filter,q|following|)		
	},
	followingSiblingArray => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _filterOutSiblings(q|ARRAY|,undef,$subpath, $filter,q|following|)		
	},
	followingSiblingHash => sub{
		my ($data, undef, $subpath,$filter) = @_;
		return _filterOutSiblings(q|HASH|,undef,$subpath, $filter,q|following|)		
	},
	followingSiblingNamed => sub{
		my ($data, $name, $subpath,$filter) = @_;
		return _filterOutSiblings(q|HASH|,$name,$subpath, $filter,q|following|)		
	},
	followingSiblingIndexed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _filterOutSiblings(q|ARRAY|,$index,$subpath, $filter,q|following|)		
	},
	followingSiblingIndexedOrNamed => sub{
		my ($data, $index, $subpath,$filter) = @_;
		return _filterOutSiblings(undef,$index,$subpath, $filter,q|following|)		
	},
	slashslash => sub{
		my ($data, undef, $subpath,undef) = @_;
		return _descendant($data,$subpath);
	}
};


# find_cycle($operatorBy);
# find_cycle($dispatcher);
# find_cycle(\@context);

$Data::Dumper::Deepcopy = 1;

sub _getObjectSubset{
	my ($data,$path) = @_;
	$path //= {};						#if not defined $path

	my %seen;
	return 
		sort {
			$a->{order} cmp $b->{order}
		}grep {
			defined $_ 
			and defined $_->{data} 
			and defined $_->{order} 
			and !$seen{$_->{data}}++
		} map {
			$dispatcher->{$_}->($data, $path->{$_}, $path->{subpath}, $path->{filter})
		} grep{
			exists $path->{$_}
		} keys %$dispatcher;
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
	push @context, {data  => \$data, type => ref $data, order => '', name => '/', size => 1, pos => 1};
	my @r = defined $query->{oper} ? 
		map {\$_} (_operation($query))								#if an operation	
		: map {$_->{data}} sort {$a->{order} cmp $b->{order}} _getObjects(@{$query->{paths}}); 	#else is a path
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
	}) or return undef;
	$q =~ s/[#\N{U+A0}-\N{U+10FFFF}]/sprintf "#%d#", ord $&/ge; #code utf8 characters with sequece #utfcode#. Marpa problem? 
	eval {$reader->read(\$q)};
	carp qq|Wrong pQuery Expression\n$@| and return undef if $@; 
	my $qp = $reader->value or return undef;
	#print "compile", Dumper $qp;
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
	my $c = Data::pQuery->compile($pQueryString) or return undef;
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

Version 0.1

=head1 Why we need another one

There are already some good approaches to xpath syntax, namely the Data::dPath 
and Data::Path. 
Nevertheless we still missing some of powerfull constructions as provided by 
xpath.

Suppose, for example, we have an array of invoices with Total, Amount and Tax 
and need to check which one does not comply to the rule "Total = Amount * (1+Tax)".

For the data structure below we can easily achieve it with this code:

	use Data::pQuery;
	use Data::Dumper;

	($\,$,) = (qq|\n|, q|,|);
	my $data = Data::pQuery->data([
	        {invoice => {
	                        Amount => 100,
	                        Tax => 0.2,
	                        Total => 120
	                }
	        },
	        {invoice => {
	                        Amount => 200,
	                        Tax => 0.15,
	                        Total => 240
	                }       
	        },
	        receipt =>{ 
	        }
	]);

	print Dumper $data->query(q$
	        //invoice[value(Total) != value(Amount) * (1 + value(Tax))]
	$)->getvalues();

The pQuery uses the xpath syntax to query any set of complex data structures, 
using keys or indexes for defining the path.
Examples:

	/0/invoice/Total
	/2
	/*/invoice[Total>100]/Total
	//Tax
	//Total[../Tax = .2]



=head1 SYNOPSIS

How to use it.

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

As we can see above the hashes structures are indexed like an element node 
in xpath and the arrays are indexed by square brackets.

The result of a query is a object Data::pQuery::Results. This object provide
us with two kind of methods

=over 4

=item getvalues and getvalue

=item getrefs and getref

=back

The first returns a list/scalar with values. The second returns a list/scalar
of references for the matched structures.


If keys contains key spaces or some special caracters used to construct a pQuery
string we can use quotes to delimite them

	#keys with spaces or especial characters should be delimited 
	#by double quotes 
	print $data->query(q|/drinks/"Alcoholic beverage"|)->getvalues();
	#not allowed

	#or by single quotes
	print $data->query(q|/drinks/'Soft drinks'[1]|)->getvalues();
	#Coke


The arrays could be index in several ways, including negative indexes,
ranges, lists and any combination of these.

	#the .. sequence indexes all array positions
	print $data->query(q|/*/*[..]|)->getvalues();
	#Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

	print $data->query(q|*/*[..]|)->getvalues(); #the leading slash is optional
	#Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes

	#negative values indexes the arrays in reverse order. -1 is the last index
	print $data->query(q|/*/*[-1]|)->getvalues();
	#Coke,pears,tomatoes


Like xpath the square brackets are used also to specify filters 
(predicates in xpath nomenclature)

	#Square brackets are also used to specify filters
	print $data->query(q|/*/*[isScalar()]|)->getvalues();
	#not allowed


The variable path length is also defined as in xpath

	#Like xpath a variable path length is defined by the sequence //
	print $data->query(q|//*[isScalar()]|)->getvalues();
	#not allowed


Unlike xpath in perl we have hashes (which are indexed like element nodes in 
xpath) and arrays (which are indexed by square brackets.) 
If we need to specify a step which could be a hash's key or an array's index 
we can use the sequence **

	#The step ** select any key or any index, while the step * only select any key
	print $data->query(q|//**[isScalar()]|)->getvalues();
	#not allowed,Tonic,Coke,bananas,apples,oranges,pears,potatoes,carrots,tomatoes


We can use pattern to match strings inside a filter

	#the filter could be a match between a string expression and a pattern
	print $data->query(q|/*/*[name() ~ "drinks"][..]|)->getvalues();
	#Tonic,Coke

	#the same as above (in this particular data-strucure)
	print $data->query(q|/*/*[name() ~ "drinks"]/**|)->getvalues();
	#Tonic,Coke


Of course, the returned values does not need be scalars (note however, in case 
of not scalares, that the returned values are just references to structures and 
not copy of them. This is normal behaviour in perl, is just a remember)

	#The returned values does not need to be scalars
	print Dumper $data->query(q|/*/vegetables|)->getvalues();

The output of above code will be (assuming the $data is defined as above)

	$VAR1 = [
	          'potatoes',
	          'carrots',
	          'tomatoes'
	        ];


Again, like in xpath we can specify zero or more filters (predicates) and/or 
combine logical expression with operators 'and' and 'or'

	#using two filters in sequence and then get the array in reverse order
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


Similar to xpath a pQuery does not need to be only a path. A function could
also be used as a pQuery

	#a query could be a function instead of a path
	print $data->query(q|names(/*/*)|)->getvalues();
	#Alcoholic beverage,Soft drinks,fruit,vegetables

	#the function 'names' returns the keys names or indexes
	print $data->query(q|names(//**)|)->getvalues();
	#drinks,Alcoholic beverage,Soft drinks,0,1,food,fruit,0,1,2,3,vegetables,0,1,2


=head1 DESCRIPTION

It looks for data-structures which match the pQuery expression and returns a list
of matched data-structures.


Currently, pQuery does not cast anything, so is impossible to compare string 
expressions with mumeric expressions or using numeric operatores. If a function
returns a string it must be compared with string operators against another 
string expression, ex: *[name() eq "keyname"]. 


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

=head1 pQuery syntax
	
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

=over 8

=item count(pathExpr)

Counts the number of matched data-structures. The count can be used inside
a filter as part of a Numeric expression. Ex: *{count(a/b) == 3}

=item exists(pathExpr)

Exists is similar to count but returns a boolean expression instead of a 
numeric value. Ex: *{exists(a/b)} 

=item not(pathExpr)

Is a boolean function. Ex: *{not(exists(a/b))} 

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

Thet group of functions isRef, isScalar, isHash, isArray and isCode returns true
is the matched data-structure is a structure of correspondent type.

If pathExpr is omitted it applies to current data-structure. 
If pathExpr evaluates to more than one data-strucures it returns the result of a 
internal logical or operation. For instance, the pQuery expression a{isScalar(*)} 
returns the data-structure referenced by the 'a' keyname if it contains at least 
one keyname associated with a scalar value. 

These functions can be used inside a filter as a boolean expression.

=back

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
	  | 'isRef' '('  OptionalPathArgs  ')'                
	  | 'isScalar' '(' OptionalPathArgs ')'               
	  | 'isArray' '(' OptionalPathArgs ')'                
	  | 'isHash' '(' OptionalPathArgs ')'                 
	  | 'isCode' '(' OptionalPathArgs ')'                 

	StringFunction ::=
	  NameFunction                                
	  | ValueFunction                             

	NameFunction ::= 
	  'name' '(' OptionalPathArgs ')'                     

	OptionalPathArgs ::= 
	  PathExpr                                    
	  |EMPTY                                      

	EMPTY ::=

	ValueFunction ::= 
	  'value' '(' OptionalPathArgs ')'                    

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
	  'names' '(' OptionalPathArgs ')'                    
	  | 'values' '(' OptionalPathArgs ')'                 


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

