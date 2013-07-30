# NAME

Data::pQuery - a xpath like processor for perl data-structures (hashes and arrays)! 

# VERSION

Version 0.1

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
             //invoice[Total != Amount * (1 + Tax)]
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



Like as in xpath it's also possible to query a function.



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
     my $results = $data->query(q|/*/*/0|);
     my @values = $results->getvalues();
     print @values;                         
     #Soda,bananas,potatoes

     my $ref = $results->getref();
     $$ref = 'Tonic';
     print $d->{drinks}->{q|Soft drinks|}->[0];     
     #Tonic

To get values we can invoke the getvalues ou getvalue methods to obtain a 
list/element matched. If what we need is to change the values we can use
getrefs or getref methods to obtain a reference to the matched 
data-structures. The getref(s) methods always returns a reference to 
matched data-structure. If the matched element is a scalar a reference to 
that scalar is returned. If the matched element is a reference array (or 
hash) a reference to that reference is returned, so we can change it and 
not only nested data-structures.



# DESCRIPTION

It looks for complex perl data-structures which match the pQuery expression 
and returns a list of matched data-structures.



Like xpath it is possible to deal with any logical or arithmetic 
expressions, ex: 

    *{count(a) == count(c) / 2 * (1 + count(b)) or d}

, or even 
query xpath functions ex: 

    count(//*)
    name(//*[last()])
    sum(//[*])



Additionally some extensions are implemented to deal with perl data-structures,
namely to choose between arrays and hashes.

Example:

Get all structures but only one which are arrays

     //[*]

Similarly to get all of hash structures, we can write

     //{*}

Besides that, some extra functions are also provide to check data type in
predicates, ex: 

     //*[isScalar()]



# METHODS

The Data::pQuery just provides two useful methods, compile and data. 
The first is used to compile a pQuery expression and the second is used
to prepare data to be queried. 

## Data::pQuery methods

### new(pQuery)

Used only internally!!! Do nothing;

### compile(pQueryString)

     my $query = Data::pQuery->compile('*');                #compile the query
     

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

    #using a predicate, to get only first level entry which contains a fruit key
    my @values3 = $data->query('/*[fruit]/*')->getvalues();
    print @values3; #bananas,unions
    #using another filter to return only elements which have the value matching 
    #a /an/ pattern
    my @values4 = $data->query('/*/*[. ~ "an"]')->getvalues();
    print @values4;# Evian,bananas

    my @values5 = $data->query('//*[isScalar()]')->getvalues();
    print @values5;#Evian,Porto,bananas,unions

                  



The method data receives a hash (or array) reference and returns a Data::pQuery::Compile object. 
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



# Xpath Compability

Unless some xpath functions, not yet implemented, and xpath axis preceding:: 
and following:: directions everything else is implemented. Probably buggly, 
sorry. I hope to fixe them as soon someone identify them

## Supported axis 

- self::
- child::
- parent::
- ancestor::
- ancestor-or-self::
- descendant::
- descendant-or-self::
- preceding-sibling::
- following::sibling::

## Supported Functions

- count(path?)
- sum(path)
- name(path?)
- position(path?)
- last()
- not(expr)
- names(path?)\*
- values(path?)\*
- value(path?)\*

(\*) not a xpath 1.0 functiona. 

names is like name but returns a list o names.

We don't support the text() funcions as we don't know what that should mean 
in perl data-structures context, but the value and values functiosn as provided
to return the value/values of current context if path argument is missing or 
the value/values of matched data-structures. That/those value/values could 
be scalar(s) or hash/array reference(s).





## Supported operators

The xpath supported operators are the following: 

    +, -, *, div, %, =, !=, (), "", '', +, -, ., .., /, //, ::, <, <=, >, >=, [], and, or 
      and 
    | (paths union)

Addicionaly pQuery also supports the following operators

    eq, ne, lt, le, gt, ge and ~ 

The ~ is the matching operator   

## Support for data types

In pQuery path expression, a digit step could mean a array index or a hash's key name.
ex:

    /a/0/b

may refere to a $d->{a}->\[0\]->{b} or to a $d->{a}->{0}->{b}. 
If a enforcement is required for select only array's index 0
the pQuery expression shloud be       

    /a/[0]/b

And similarity for hash' key '0'    

    /a/{0}/b

The curly bracket could also be useful to refere to keys with spaces or any special 
character. Some examples

    /{two words as a keys}//{key with a / or a +}/*

The curly and square brackets could also be used with axis and wildcard \*. Examples:

    //{*}
    //[*]
    //*/parent::[b]
    //a//parent::{*}
    //*[self::{*} = 3 or self::[*] > 10]

If a hash key is just a \* the path expression is also posible using instead curly 
brackets, quotes (double or single)

    //"*"/b
    //a/'*'

Inside curly brackets, or quotes a backslash is used to escape { or } if the step 
delimited by those characters and " when used inside doubles quotes or  ' 
for single quotes delimitation,or escape itself. In any other situation is 
literaly interpreted

    //"2\""
    //'hash\'s key'
    //{\{}/
    

    //'2"'
    //"hash\'s key"
    //'{'
    

    //{\\}
    //"\\"
    //'\\'





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


