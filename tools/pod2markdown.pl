#!/usr/bin/perl
#
# This file is part of Pod-Markdown
#
# This software is copyright (c) 2004 by Marcel Gruenauer.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use strict;
use warnings;
# PODNAME: pod2markdown
# ABSTRACT: Convert POD text to Markdown

use Pod::Markdown;

my $in_fh  = get_handle(shift(@ARGV), '<', \*STDIN);
my $out_fh = get_handle(shift(@ARGV), '>', \*STDOUT);

convert($in_fh, $out_fh);

sub convert {
    my ($in_file, $out_file) = @_;
    my $parser = Pod::Markdown->new;
    $parser->parse_from_filehandle($in_file);
    print $out_file $parser->as_markdown;
}

sub get_handle {
  my ($path, $op, $default) = @_;
  (!defined($path) || $path eq '-') ? $default : do {
    open(my $fh, $op, $path)
      or die "Failed to open '$path': $!\n";
    $fh;
  };
}

__END__

=pod

=encoding utf-8

=for :stopwords Marcel Gruenauer Victor Moral Ryan C. Thompson <rct at thompsonclan d0t
org> Aristotle Pagaltzis Randy Stauner ACKNOWLEDGEMENTS

=head1 NAME

pod2markdown - Convert POD text to Markdown

=head1 VERSION

version 1.322

=head1 SYNOPSIS

    # parse STDIN, print to STDOUT
    $ pod2markdown < POD_File > Markdown_File

    # parse file, print to STDOUT
    $ pod2markdown input.pod

    # parse file, print to file
    $ pod2markdown input.pod output.mkdn

    # parse STDIN, print to file
    $ pod2markdown - output.mkdn

=head1 DESCRIPTION

This program uses L<Pod::Markdown> to convert POD into Markdown sources.

It accepts two optional arguments:

=over 4

=item *

input pod file (defaults to C<STDIN>)

=item *

output markdown file (defaults to C<STDOUT>)

=back

=head1 SEE ALSO

This program is strongly based on C<pod2mdwn> from L<Module::Build::IkiWiki>.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Victor Moral <victor@taquiones.net>

=item *

Ryan C. Thompson <rct at thompsonclan d0t org>

=item *

Aristotle Pagaltzis <pagaltzis@gmx.de>

=item *

Randy Stauner <rwstauner@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
