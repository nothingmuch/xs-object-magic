#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Scalar::Util qw(reftype);

use ok 'XS::Object::Magic';

my $o = XS::Object::Magic::Test->new;

isa_ok($o, "XS::Object::Magic::Test");

is( reftype($o), "HASH", "reftype is hash" );

is( scalar(keys %$o), 0, "hash is empty" );

can_ok( $o, "count" );

is( $o->count, 1, "count method" );
is( $o->count, 2, "count method" );
is( $o->count, 3, "count method" );

is( XS::Object::Magic::Test::destroyed(), 0, "not yet destroyed" );

undef $o;

is( XS::Object::Magic::Test::destroyed(), 1, "destroyed" );
