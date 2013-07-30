NAME
    Data::pQuery - a xpath like processor for perl data-structures (hashes
    and arrays)!

VERSION
    Version 0.1

Why we need another one
    There are already some good approaches to xpath syntax, namely the
    Data::dPath and Data::Path. Nevertheless we still missing some of
    powerfull constructions as provided by xpath.

    Suppose, for example, we have an array of invoices with Total, Amount
    and Tax and need to check which one does not comply to the rule "Total =
    Amount * (1+Tax)".

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

    The pQuery uses the xpath 1.0 syntax to query any set of complex perl
    data structures, using keys or indexes for defining the path.

    Examples:

            /0/invoice/Total
            /2
            /*/invoice[Total>100]/Total
            //Tax
            //Total[../Tax = .2]
            //*[count(itens/*) > 1][1]
            sum(//Total)

    Like as in xpath it's possible to query a function instead of quering
    for a set of data structures.

SYNOPSIS
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
            my $results = $data->query(q|/*/*/0|);
            my @values = $results->getvalues();
            print @values;                                  
            #Soda,bananas,potatoes

            my $ref = $results->getref();
            $$ref = 'Tonic';
            print $d->{drinks}->{q|Soft drinks|}->[0];      
            #Tonic

    As we can see above the hashes structures and array indexes are indexed
    like an element node in xpath.

DESCRIPTION
    It looks for data-structures which match the pQuery expression and
    returns a list of matched data-structures.

    Like xpath it is possible to deal with any logical or arithmetic
    expressions, ex: *{count(a) == count(c) / 2 * (1 + count(b)) or d}

METHODS
    The Data::pQuery just provides two useful methods, compile and data. The
    first is used to complie a pQuery expression and the second is used to
    prepare data to be queried.

  Data::pQuery methods
    new(pQuery)
    Used only internally!!! Do nothing;

    compile(pQueryString)
            my $query = Data::pQuery->compile('*');                         #compile the query
        
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

    The compile method receives a pQuery string, compiles it and returns a
    Data::pQuery::Data object. This is the prefered method to run the same
    query over several data-structures.

    data(dataRef)
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

            #using a predicate, to get only first level entry which contains a fruit key
            my @values3 = $data->query('/*[fruit]/*')->getvalues();
            print @values3; #bananas,unions
            #using another filter to return only elements which have the value matching 
            #a /an/ pattern
            my @values4 = $data->query('/*/*[value() ~ "an"]')->getvalues();
            print @values4;# Evian,bananas

            my @values5 = $data->query('//*[isScalar()]')->getvalues();
            print @values5;#Evian,Porto,bananas,unions

    The method data receives a hash or array reference and returns a
    Data::pQuery::Compile object. This is the prefered method to run several
    query over same data.

  Data::pQuery::Data methods
    data(data)
    Executes the query over data and returns a Data::pQuery::Results object

  Data::pQuery::Compiler methods
    query(pQueryString)
    Compile a pQuery string, query the data and returns a
    Data::pQuery::Results object

  Data::pQuery::Results methods
    getrefs()
Returns a list os references for each matched data;
    getref()
Returns a reference for first matched data;
    getvalues()
Returns a list of values for each matched data;
    getvalue()
Returns the value of first matched data;
  pQuery grammar
    Marpa::R2 is used to parse the pQuery expression. Bellow is the complete
    grammar

    :default ::= action => ::array :start ::= Start

    Start ::= OperExp action => _do_arg1

    OperExp ::= PathExpr action => _do_path |Function action => _do_arg1

    Function ::= NumericFunction action => _do_arg1 | StringFunction action
    => _do_arg1 | ListFunction action => _do_arg1

    PathExpr ::= absolutePath action => _do_absolutePath | relativePath
    action => _do_relativePath | PathExpr '|' PathExpr action =>
    _do_pushArgs2array

    PredPathExpr ::= absolutePath action => _do_absolutePath |
    stepPathNoDigitStart action => _do_relativePath | './' stepPath action
    => _do_relativePath2 | PredPathExpr '|' PredPathExpr action =>
    _do_pushArgs2array

    relativePath ::= stepPath action => _do_arg1

    absolutePath ::= subPath action => _do_arg1

    subPath ::= '/' stepPath action => _do_arg2 | '//' stepPath action =>
    _do_vlen

    stepPath ::= step Filter subPath action => _do_stepFilterSubpath | step
    Filter action => _do_stepFilter | step subPath action => _do_stepSubpath
    | step action => _do_arg1

    step ::= keyOrAxis action => _do_arg1 |index action => _do_arg1

    index ::= UINT action => _do_array_hash_index

    stepPathNoDigitStart ::= keyOrAxis Filter subPath action =>
    _do_stepFilterSubpath | keyOrAxis Filter action => _do_stepFilter |
    keyOrAxis subPath action => _do_stepSubpath | keyOrAxis action =>
    _do_arg1

    keyOrAxis ::= keyname action => _do_keyname | '[' UINT ']' action =>
    _do_array_index | '.' action => _do_self | '[.]' action => _do_selfArray
    | '{.}' action => _do_selfHash | 'self::*' action => _do_self |
    'self::[*]' action => _do_selfArray | 'self::{*}' action => _do_selfHash
    | 'self::' keyname action => _do_selfNamed | 'self::' UINT action =>
    _do_selfIndexedOrNamed | 'self::[' UINT ']' action => _do_selfIndexed |
    '*' action => _do_child | '[*]' action => _do_childArray | '{*}' action
    => _do_childHash | 'child::*' action => _do_child | 'child::[*]' action
    => _do_childArray | 'child::{*}' action => _do_childHash | 'child::'
    keyname action => _do_childNamed | 'child::' UINT action =>
    _do_childIndexedOrNamed | 'child::[' UINT ']' action => _do_childIndexed
    | '..' action => _do_parent | '[..]' action => _do_parentArray | '{..}'
    action => _do_parentHash | 'parent::*' action => _do_parent |
    'parent::[*]' action => _do_parentArray | 'parent::{*}' action =>
    _do_parentHash | 'parent::' keyname action => _do_parentNamed |
    'parent::' UINT action => _do_parentIndexedOrNamed | 'parent::[' UINT
    ']' action => _do_parentIndexed | 'ancestor::*' action => _do_ancestor |
    'ancestor::[*]' action => _do_ancestorArray | 'ancestor::{*}' action =>
    _do_ancestorHash | 'ancestor::' keyname action => _do_ancestorNamed |
    'ancestor::' UINT action => _do_ancestorIndexedOrNamed | 'ancestor::['
    UINT ']' action => _do_ancestorIndexed | 'ancestor-or-self::*' action =>
    _do_ancestorOrSelf | 'ancestor-or-self::[*]' action =>
    _do_ancestorOrSelfArray | 'ancestor-or-self::{*}' action =>
    _do_ancestorOrSelfHash | 'ancestor-or-self::' keyname action =>
    _do_ancestorOrSelfNamed | 'ancestor-or-self::' UINT action =>
    _do_ancestorOrSelfIndexedOrNamed | 'ancestor-or-self::[' UINT ']' action
    => _do_ancestorOrSelfIndexed | 'descendant::*' action => _do_descendant
    | 'descendant::[*]' action => _do_descendantArray | 'descendant::{*}'
    action => _do_descendantHash | 'descendant::' keyname action =>
    _do_descendantNamed | 'descendant::' UINT action =>
    _do_descendantIndexedOrNamed | 'descendant::[' UINT ']' action =>
    _do_descendantIndexed | 'descendant-or-self::*' action =>
    _do_descendantOrSelf | 'descendant-or-self::[*]' action =>
    _do_descendantOrSelfArray | 'descendant-or-self::{*}' action =>
    _do_descendantOrSelfHash | 'descendant-or-self::' keyname action =>
    _do_descendantOrSelfNamed | 'descendant-or-self::' UINT action =>
    _do_descendantOrSelfIndexedOrNamed | 'descendant-or-self::[' UINT ']'
    action => _do_descendantOrSelfIndexed | 'preceding-sibling::*' action =>
    _do_precedingSibling | 'preceding-sibling::[*]' action =>
    _do_precedingSiblingArray | 'preceding-sibling::{*}' action =>
    _do_precedingSiblingHash | 'preceding-sibling::' keyname action =>
    _do_precedingSiblingNamed | 'preceding-sibling::' UINT action =>
    _do_precedingSiblingIndexedOrNamed | 'preceding-sibling::[' UINT ']'
    action => _do_precedingSiblingIndexed | 'following-sibling::*' action =>
    _do_followingSibling | 'following-sibling::[*]' action =>
    _do_followingSiblingArray | 'following-sibling::{*}' action =>
    _do_followingSiblingHash | 'following-sibling::' keyname action =>
    _do_followingSiblingNamed | 'following-sibling::' UINT action =>
    _do_followingSiblingIndexedOrNamed | 'following-sibling::[' UINT ']'
    action => _do_followingSiblingIndexed

    IndexExprs ::= IndexExpr+ separator => <comma>

    IndexExpr ::= IntExpr action => _do_index_single | rangeExpr action =>
    _do_arg1

    rangeExpr ::= IntExpr '..' IntExpr action => _do_index_range |IntExpr
    '..' action => _do_startRange | '..' IntExpr action => _do_endRange

    Filter ::= IndexFilter | LogicalFilter | Filter Filter action =>
    _do_mergeFilters

    LogicalFilter ::= '[' LogicalExpr ']' action => _do_boolean_filter

    IndexFilter ::= '[' IndexExprs ']' action => _do_index_filter

    IntExpr ::= WS ArithmeticIntExpr WS action => _do_arg2

     ArithmeticIntExpr ::=
            INT                                                                                                                                                             action => _do_arg1
            | IntegerFunction                                                                                                               action => _do_arg1
            | '(' IntExpr ')'                                                                                                       action => _do_group
            || '-' ArithmeticIntExpr                                                                                action => _do_unaryOperator
             | '+' ArithmeticIntExpr                                                                                action => _do_unaryOperator
            || IntExpr '*' IntExpr                                                                                  action => _do_binaryOperation
             | IntExpr 'div' IntExpr                                                                                action => _do_binaryOperation
    #        | IntExpr ' /' IntExpr                                                                                 action => _do_binaryOperation 
    #        | IntExpr '/ ' IntExpr                                                                                 action => _do_binaryOperation 
             | IntExpr '%' IntExpr                                                                                  action => _do_binaryOperation
            || IntExpr '+' IntExpr                                                                                  action => _do_binaryOperation
             | IntExpr '-' IntExpr                                                                                  action => _do_binaryOperation

    NumericExpr ::= WS ArithmeticExpr WS action => _do_arg2

    ArithmeticExpr ::= NUMBER action => _do_arg1 || PredPathExpr action =>
    _do_getValueOperator | NumericFunction action => _do_arg1 | '('
    NumericExpr ')' action => _do_group || '-' ArithmeticExpr action =>
    _do_unaryOperator | '+' ArithmeticExpr action => _do_unaryOperator ||
    NumericExpr '*' NumericExpr action => _do_binaryOperation | NumericExpr
    'div' NumericExpr action => _do_binaryOperation # | NumericExpr ' /'
    NumericExpr action => _do_binaryOperation # | NumericExpr '/ '
    NumericExpr action => _do_binaryOperation | NumericExpr '%' NumericExpr
    action => _do_binaryOperation || NumericExpr '+' NumericExpr action =>
    _do_binaryOperation | NumericExpr '-' NumericExpr action =>
    _do_binaryOperation

    LogicalExpr ::= WS LogicalFunction WS action => _do_arg2 || WS
    compareExpr WS action => _do_arg2

    compareExpr ::= PredPathExpr action => _do_exists || AnyTypeExpr '<'
    AnyTypeExpr action => _do_binaryOperation | AnyTypeExpr '<=' AnyTypeExpr
    action => _do_binaryOperation | AnyTypeExpr '>' AnyTypeExpr action =>
    _do_binaryOperation | AnyTypeExpr '>=' AnyTypeExpr action =>
    _do_binaryOperation | StringExpr 'lt' StringExpr action =>
    _do_binaryOperation | StringExpr 'le' StringExpr action =>
    _do_binaryOperation | StringExpr 'gt' StringExpr action =>
    _do_binaryOperation | StringExpr 'ge' StringExpr action =>
    _do_binaryOperation | StringExpr '~' RegularExpr action =>
    _do_binaryOperation | StringExpr '!~' RegularExpr action =>
    _do_binaryOperation | NumericExpr '===' NumericExpr action =>
    _do_binaryOperation | NumericExpr '!==' NumericExpr action =>
    _do_binaryOperation | AnyTypeExpr '==' AnyTypeExpr action =>
    _do_binaryOperation | AnyTypeExpr '=' AnyTypeExpr action =>
    _do_binaryOperation #to be xpath compatible | AnyTypeExpr '!='
    AnyTypeExpr action => _do_binaryOperation | StringExpr 'eq' StringExpr
    action => _do_binaryOperation | StringExpr 'ne' StringExpr action =>
    _do_binaryOperation || LogicalExpr 'and' LogicalExpr action =>
    _do_binaryOperation || LogicalExpr 'or' LogicalExpr action =>
    _do_binaryOperation

    AnyTypeExpr ::= WS allTypeExp WS action => _do_arg2

    allTypeExp ::= NumericExpr action => _do_arg1 |StringExpr action =>
    _do_arg1 || PredPathExpr action => _do_getValueOperator

    StringExpr ::= WS allStringsExp WS action => _do_arg2

    allStringsExp ::= STRING action => _do_arg1 | StringFunction action =>
    _do_arg1 | PredPathExpr action => _do_getValueOperator || StringExpr
    '||' StringExpr action => _do_binaryOperation

    RegularExpr ::= WS STRING WS action => _do_re

    LogicalFunction ::= 'not' '(' LogicalExpr ')' action => _do_func |
    'isRef' '(' OptionalPathArgs ')' action => _do_func | 'isScalar' '('
    OptionalPathArgs ')' action => _do_func | 'isArray' '(' OptionalPathArgs
    ')' action => _do_func | 'isHash' '(' OptionalPathArgs ')' action =>
    _do_func | 'isCode' '(' OptionalPathArgs ')' action => _do_func

    StringFunction ::= NameFunction action => _do_arg1 | ValueFunction
    action => _do_arg1

    NameFunction ::= 'name' '(' OptionalPathArgs ')' action => _do_func

    OptionalPathArgs ::= RequiredPathArgs action => _do_arg1 | EMPTY action
    => _do_arg1

    RequiredPathArgs ::= WS PathExpr WS action => _do_arg2

    EMPTY ::=

    ValueFunction ::= 'value' '(' OptionalPathArgs ')' action => _do_func

    CountFunction ::= 'count' '(' RequiredPathArgs ')' action => _do_func

    LastFunction ::= 'last' '(' OptionalPathArgs ')' action => _do_func

    PositionFunction ::= 'position' '(' OptionalPathArgs ')' action =>
    _do_func

    SumFunction ::= 'sum' '(' RequiredPathArgs ')' action => _do_func

    SumProductFunction ::= 'sumproduct' '(' RequiredPathArgs ','
    RequiredPathArgs ')' action => _do_funcw2args

    NumericFunction ::= IntegerFunction action => _do_arg1 |ValueFunction
    action => _do_arg1 |SumFunction action => _do_arg1 |SumProductFunction
    action => _do_arg1

    IntegerFunction ::= CountFunction action => _do_arg1 |LastFunction
    action => _do_arg1 |PositionFunction action => _do_arg1

    ListFunction ::= 'names' '(' OptionalPathArgs ')' action => _do_func |
    'values' '(' OptionalPathArgs ')' action => _do_func | 'lasts' '('
    OptionalPathArgs ')' action => _do_func | 'positions' '('
    OptionalPathArgs ')' action => _do_func

     NUMBER ::= 
            unumber                                                                                                                                                 action => _do_arg1
            | '-' unumber                                                                                                                   action => _do_join
            | '+' unumber                                                                                                                   action => _do_join

    unumber ~ uint | uint frac | uint exp | uint frac exp | frac | frac exp

    uint ~ digits

    digits ~ [\d]+

    frac ~ '.' digits

    exp ~ e digits

    e ~ 'e' | 'e+' | 'e-' | 'E' | 'E+' | 'E-'

    INT ::= UINT action => _do_arg1 | '+' UINT action => _do_join #avoid
    ambiguity | '-' UINT action => _do_join #avoid ambiguity

    UINT ~digits

    STRING ::= double_quoted action => _do_double_quoted | single_quoted
    action => _do_single_quoted

    single_quoted ~ ['] single_quoted_chars [']

    single_quoted_chars ~ single_quoted_char*

    single_quoted_char ~ [^'] | '\' [']

    double_quoted ~ ["] double_quoted_chars ["]

    double_quoted_chars ~ double_quoted_char*

    double_quoted_char ~ [^"] | '\' '"'

    keyname ::= keyword action => _do_token | STRING action => _do_arg1 |
    curly_delimited_string action => _do_curly_delimited_string

    curly_delimited_string ~ '{' curly_delimited_chars '}'

    curly_delimited_chars ~ curly_delimited_char*

    curly_delimited_char ~ [^}{] | '\' '{' | '\' '}'

    keyword ~ ID

    ID ~ token | token ':' token #to allow replication of xml tags names
    with namespaces

    token #must have at least one non digit ~ notreserved | token [\d] |
    [\d] token

    notreserved ~ [^\d:./*,'"|\s\]\[\(\)\{\}\\+-<>=!]+

    # :discard # ~ WS

    WS ::= whitespace |EMPTY

    whitespace ~ [\s]+

    comma ~ ','

AUTHOR
    Isidro Vila Verde, `<jvverde at gmail.com>'

BUGS
    Send email to `<jvverde at gmail.com>' with subject Data::pQuery

SUPPORT
    You can find documentation for this module with the perldoc command.

        perldoc Data::pQuery

LICENSE AND COPYRIGHT
    Copyright 2013 Isidro Vila Verde.

    This program is free software; you can redistribute it and/or modify it
    under the terms of the the Artistic License (2.0). You may obtain a copy
    of the full license at:

    http://www.perlfoundation.org/artistic_license_2_0

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

