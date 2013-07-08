#!/usr/bin/perl

use strict;
use Pod::Readme;
my $parser = Pod::Readme->new();

# Read POD from STDIN and write to STDOUT
$parser->parse_from_filehandle;

# Read POD from Module.pm and write to README
#$parser->parse_from_file('Module.pm', 'README');
