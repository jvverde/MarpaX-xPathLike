#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::xPathLike' ) || print "Bail out!\n";
}

diag( "Testing Data::xPathLike $Data::xPathLike::VERSION, Perl $], $^X" );
