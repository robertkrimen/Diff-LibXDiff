#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Diff::LibXDiff;

my ($patched, $rejected, $string1, $string2);

($patched, $rejected) = Diff::LibXDiff->patch( 'A', <<'_END_' );
@@ -1,1 +1,1 @@
-A
\ No newline at end of file
+b
\ No newline at end of file
_END_
is( $patched, 'b' );

$string1 = <<_END_;
apple
banana
cherry
_END_

$string2 = <<_END_;
apple
grape
cherry
lime
_END_

($patched, $rejected) = Diff::LibXDiff->patch( $string1, <<'_END_' );
@@ -1,3 +1,4 @@
 apple
-banana
+grape
 cherry
+lime
_END_
is( $patched, $string2 );

__END__
$diff = Diff::LibXDiff->diff( 'A', 'b' );
is( $diff, <<'_END_');
@@ -1,1 +1,1 @@
-A
\ No newline at end of file
+b
\ No newline at end of file
_END_

$string2 = <<_END_;
apple
grape
cherry
lime
_END_

$diff = Diff::LibXDiff->diff( $string1, $string2 );

is( $diff, <<'_END_' );
@@ -1,3 +1,4 @@
 apple
-banana
+grape
 cherry
+lime
_END_
