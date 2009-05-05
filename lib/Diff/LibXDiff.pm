package Diff::LibXDiff;

use warnings;
use strict;

=head1 NAME

Text::LibXDiff -

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

require Exporter;
require DynaLoader;

our @ISA = qw/Exporter DynaLoader/;
our @EXPORT_OK = qw//;

bootstrap Diff::LibXDiff $VERSION;

warn _xdiff("Ab\n", "Cd\nYoink!2\n");

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-libxdiff at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-LibXDiff>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::LibXDiff


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-LibXDiff>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-LibXDiff>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-LibXDiff>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-LibXDiff/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::LibXDiff
