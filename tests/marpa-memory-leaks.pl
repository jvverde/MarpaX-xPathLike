#!/usr/bin/perl
    use strict;
    use warnings FATAL => 'all';
    use Marpa::R2;
    use Data::Dumper;

    my $grammar = Marpa::R2::Scanless::G->new({
     action_object => __PACKAGE__,
     source => \(<<'END_OF_SOURCE'),
     :default ::= action => ::array
     :start ::= path
     path ::=
      step               action => _do_step
     step ~ [a-z]+ 
END_OF_SOURCE
    });

    sub _do_step{ return {step => $_[1]}};


    sub new {}     #The Marpa::R2 needs it
    sub compile{
     my ($query) = @_; 
     return undef unless $query;

     my $reader = Marpa::R2::Scanless::R->new({
      grammar => $grammar,
      trace_terminals => 0,
     });
     $reader->read(\$query);
     print Dumper $reader->value;
    }

    compile($_) foreach ('aaaa'..'zzzz'); 
