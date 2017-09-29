#!/usr/bin/perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain qw(explain);
use Test2::Tools::Exception qw/lives dies/;

use Log::Log4perl;
use Test2::Log::Log4perl;

my $logger   = Log::Log4perl->get_logger("Foo");
my $tlogger  = Test2::Log::Log4perl->get_logger("Foo");

########################################################

like(
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error(qr/hair/);
    $logger->error("my hair is on fire!");
    Test2::Log::Log4perl->end();
  },
  array {
      event Ok => sub {
        call pass => 1
      };
      end;
  },
  "basic qr test",
);

########################################################

my $DEFAULT_FLAGS = $] < 5.013005 ? '-xism' : '^';

like(
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error(qr/tree/);
    $logger->error("my hair is on fire!");
    Test2::Log::Log4perl->end();
  },
  array {
      fail_events Ok => sub {
        call pass => 0
      };
      event Diag => {
        message => qr/{message}.*my hair is on fire!.*tree/
      };
      end;
  },
  "getting wrong message",
);

########################################################

done_testing;
