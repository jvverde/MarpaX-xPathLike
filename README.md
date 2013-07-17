# NAME

Data::pQuery - a xpath like processor for perl data-structures (hashes and arrays)! 

# VERSION

Version 0.02

# Why we need another one

There are already some good approaches to xpath syntax, namely the Data::dPath 
and Data::Path. 
Nevertheless we still missing some of powerfull constructions as provided by 
xpath.

Suppose, for example, we have an array of invoices with Total, Amount and Tax 
and need to check which one does not comply to the rule "Total = Amount \* (1+Tax)".

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

The pQuery sintax is very similar to the xpath but with some minor exceptions,
as showed in examples bellow.



# SYNOPSIS

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

- getvalues and getvalue
- getrefs and getref

The first returns a list/scalar with values. The second returns a list/scalar
of references for the matched structures.



I keys contains key spaces or some special caracters used to construct a pQuery
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
we can use the sequence \*\*

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



Similar to xpath a query does not need to be only a path. A function could
also be used as a query

	#a query could be a function instead of a path
	print $data->query(q|names(/*/*)|)->getvalues();
	#Alcoholic beverage,Soft drinks,fruit,vegetables

	#the function 'names' returns the keys names or indexes
	print $data->query(q|names(//**)|)->getvalues();
	#drinks,Alcoholic beverage,Soft drinks,0,1,food,fruit,0,1,2,3,vegetables,0,1,2



# DESCRIPTION

It looks for data-structures which match the pQuery expression and returns a list
of matched data-structures.



Currently, pQuery does not cast anything, so is impossible to compare string 
expressions with mumeric expressions or using numeric operatores. If a function
returns a string it must be compared with string operators against another 
string expression, ex: \*\[name() eq "keyname"\]. 



Like xpath it is possible to deal with any logical or arithmetic 
expressions, ex: \*{count(a) == count(c) / 2 \* (1 + count(b)) or d}



# METHODS

The Data::pQuery just provides two useful methods, compile and data. 
The first is used to complie a pQuery expression and the second is used
to prepare data to be queried. 

## Data::pQuery methods

### new(pQuery)

Used only internally!!! Do nothing;

### compile(pQueryString)

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

### data(dataRef)

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

## Data::pQuery::Data methods

### data(data)

Executes the query over data and returns a Data::pQuery::Results object

## Data::pQuery::Compiler methods

### query(pQueryString)

Compile a pQuery string, query the data and returns a Data::pQuery::Results object

## Data::pQuery::Results methods

### getrefs()
Returns a list os references for each matched data;

### getref()
Returns a reference for first matched data;

### getvalues()
Returns a list of values for each matched data;

### getvalue()
Returns the value of first matched data;

# pQuery sintax
	

A pQuery expression is a function or a path. 

## pQuery Path Expressions

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



A wildcard (\*) means any key name and a double wildcard (\*\*) means any key name
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



### Comparison expressions

A comparison expression can compare two strings expressions or two numeric 
expressions. Its impossible to compare a string expression with a numeric 
expression. Nothing is cast! It is also impossible to use numeric comparison
operator to compare strings expressions.

#### Numeric comparison operators

- NumericExpr < NumericExpr	
- NumericExpr <= NumericExpr							
- NumericExpr > NumericExpr							
- NumericExpr >= NumericExpr
- NumericExpr == NumericExpr							
- NumericExpr != NumericExpr							

#### String comparison operators

- StringExpr lt StringExpr							
- StringExpr le StringExpr							
- StringExpr gt StringExpr							
- StringExpr ge StringExpr							
- StringExpr ~ RegularExpr							
- StringExpr !~ RegularExpr							
- StringExpr eq StringExpr							
- StringExpr ne StringExpr	



## pQuery Functions
	

Any function can be used as query  and some of them can also
be used as part of a numeric or string expression inside a filter.

Currently only the following function are supported 

- count(pathExpr)

    Counts the number of matched data-structures. The count can be used inside
    a filter as part of a Numeric expression. Ex: \*{count(a/b) == 3}

- exists(pathExpr)

    Exists is similar to count but returns a boolean expression instead of a 
    numeric value. Ex: \*{exists(a/b)} 

- not(pathExpr)

    Is a boolean function. Ex: \*{not(exists(a/b))} 

- names(pathExpr?)

    Returns a list of names of matched data-structures. 
    If pathExpr is omitted it returns the name of current data-structure. 
    If the data-structure is a hash entry it returns the keyname.
    If the data-structure is an array entry it returns the index.
    PathExpr is any valid pQuery path expression. 
    If it starts with a slash it means an absolute path, otherwise it is a 
    path relative to the current data-structure.
    A empty list will be returned if nothing matches.   

- name(pathExpr?)

    name is a particular case of names which just returns the name of first matched 
    data-structure or undef if nothing matches. 

    This function can be part of a string expression inside a filter

- values(pathExpr?)
 

    Like names but returns the values instead of keys or indexs. 
    The same rules apllies for the optional pathExpr argument.

- value(pathExpr?)

    Returns the value of first matched data-structure or undef in none matches.
    If pathExpr is omitted it returns the value of current data-structure.  

    This function can be part of a string expression or a numeric expression inside a filter

- isXXXX(pathExpr?)

    Thet group of functions isRef, isScalar, isHash, isArray and isCode returns true
    is the matched data-structure is a structure of correspondent type.

    If pathExpr is omitted it applies to current data-structure. 
    If pathExpr evaluates to more than one data-strucures it returns the result of a 
    internal logical or operation. For instance, the pQuery expression a{isScalar(\*)} 
    returns the data-structure referenced by the 'a' keyname if it contains at least 
    one keyname associated with a scalar value. 

    These functions can be used inside a filter as a boolean expression.

## pQuery grammar

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

# AUTHOR

Isidro Vila Verde, `<jvverde at gmail.com>`

# BUGS

Send email to `<jvverde at gmail.com>` with subject Data::pQuery



Please report any bugs or feature requests to `bug-data-pquery at rt.cpan.org`, or through
the web interface at [http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-pQuery](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-pQuery).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::pQuery



- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-pQuery](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-pQuery)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Data-pQuery](http://annocpan.org/dist/Data-pQuery)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Data-pQuery](http://cpanratings.perl.org/d/Data-pQuery)

- Search CPAN

    [http://search.cpan.org/dist/Data-pQuery/](http://search.cpan.org/dist/Data-pQuery/)



# ACKNOWLEDGEMENTS



# LICENSE AND COPYRIGHT

Copyright 2013 Isidro Vila Verde.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic\_license\_2\_0)

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


