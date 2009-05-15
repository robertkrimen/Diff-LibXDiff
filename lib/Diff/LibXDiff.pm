package Diff::LibXDiff;

use warnings;
use strict;

=head1 NAME

Diff::LibXDiff - Calculate a diff with LibXDiff (via XS)

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Diff::LibXDiff;

    my $string1 = <<_END_
    apple
    banana
    cherry
    _END_

    my $string2 = <<_END_
    apple
    grape
    cherry
    lime
    _END_

    my $diff = Diff::LibXDiff->diff( $string1, $string2 )

    # $diff is ...

    @@ -1,3 +1,4 @@
     apple
    -banana
    +grape
     cherry
    +lime

=head1 DESCRIPTION

Diff::LibXDiff is a binding of LibXDiff (L<http://www.xmailserver.org/xdiff-lib.html>) to Perl via XS

LibXDiff is the basis of the diff engine for git

Currently only the C<diff> method is supported, and that only with text diffing. More coming soon.

=cut

require Exporter;
require DynaLoader;

use Carp::Clan;

our @ISA = qw/Exporter DynaLoader/;
our @EXPORT_OK = qw//;

bootstrap Diff::LibXDiff $VERSION;

=head1 METHODS

=head2 $diff = Diff::LibXDiff->diff( $string1, $string2 )

Calculate the textual diff of $string1 and $string2 and return the result as a string

=cut

sub diff {
    my $self = shift;
    my ($string1, $string2) = @_;

    croak "string1 not defined" unless defined $string1;
    croak "string2 not defined" unless defined $string2;
    croak "string1 isn't a string" if ref $string1;
    croak "string2 isn't a string" if ref $string2;

    my $result = _xdiff( $string1, $string2 );

    my @error = @{ $result->{error} };

    croak join '', "Unable to process the diff of string1 & string2: ", join ', ', @error if @error;

    return $result->{stringr};
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SEE ALSO

L<http://www.xmailserver.org/xdiff-lib.html>

L<Algorithm::Diff>

=head1 BUGS

Please report any bugs or feature requests to C<bug-diff-libxdiff at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Diff-LibXDiff>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Diff::LibXDiff


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Diff-LibXDiff>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Diff-LibXDiff>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Diff-LibXDiff>

=item * Search CPAN

L<http://search.cpan.org/dist/Diff-LibXDiff/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Diff::LibXDiff
