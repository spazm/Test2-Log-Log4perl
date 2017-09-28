#!/usr/bin/perl

####################################################################
# Description of what this test does:
# Checks to see if _match does the right thing
####################################################################

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain qw(explain);
use Test2::Tools::Exception qw/lives dies/;

use Test2::Log::Log4perl;

# colourising the output if we want to
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

###################################
# user editable parts


ok(Test2::Log::Log4perl->_matches("foo", "foo"), "foo foo");
ok(!Test2::Log::Log4perl->_matches("foo", "bar"), "foo bar");

ok(Test2::Log::Log4perl->_matches("foo", qr/foo/), "foo qr/foo/");
ok(!Test2::Log::Log4perl->_matches("foo", qr/bar/), "foo qr/bar/");

ok(!Test2::Log::Log4perl->_matches("foo", {}), "hash");
ok(!Test2::Log::Log4perl->_matches("foo", bless({}, "bar")), "object");

ok(Test2::Log::Log4perl->_matches({a=>1},       {a=>1}),       "hash to hash");
ok(Test2::Log::Log4perl->_matches({a=>1, b=>1}, {a=>1}),       "hash to subhash");
ok(!Test2::Log::Log4perl->_matches({a=>1},      {a=>1, b=>1}), "subhash to hash");

done_testing;
