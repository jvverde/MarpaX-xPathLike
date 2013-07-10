# NAME

Data::pQuery - a xpath like processor for json like data-objects (hashes and arrays)! 

# VERSION

Version 0.02

# SYNOPSIS

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



# METHODS

The Data::pQuery just provides two methods

## Data::pQuery methods



### new(pQuery)

Used only internally!!! Do nothing;

### compile(pQueryString)

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



## Data::pQuery::Data methods

### data(data)

Executes the query over data and returns a Data::pQuery::Results object



## Data::pQuery::Compiler methods

### query(pQueryString)

Compile a pQuery string, query the data and returns a Data::pQuery::Results object

## Data::pQuery::Results methods

### getrefs()
Returns a list os references for each matched data-object;

### getref()
Returns a reference for first matched data-object;

### getvalues()
Returns a list of values for each matched data-object;

### getvalue()
Returns the value of first matched data-object;

# pQuery sintax
	

A pQuery expression is a function or a path. 

## pQuery Path Expressions

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



A wildcard (\*) means any key name and a double wildcard (\*\*) means any key name
or any index under current object. 

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

## pQuery grammar

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


