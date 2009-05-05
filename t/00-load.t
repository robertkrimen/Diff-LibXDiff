#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Diff::LibXDiff' );
}

diag( "Testing Diff::LibXDiff $Diff::LibXDiff::VERSION, Perl $], $^X" );
