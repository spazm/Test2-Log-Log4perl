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
my $t2logger = Test2::Log::Log4perl->get_logger("Bar");

########################################################
# test that we ignore some priorities

like(
  intercept {
    Test2::Log::Log4perl->start(
      ignore_priority => "warn",
    );
    $tlogger->error("my hair is on fire!");

    $logger->trace("ignore ignore ignore");
    $logger->debug("ignore me");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("my hair is on fire!");

    Test2::Log::Log4perl->end();
  },
  array {
      event Ok => sub {
        call pass => 1
      }
  },
  "ignore_priority warn",
);

########################################################
# but they go back at the start of the next thing
#
like(
  intercept {
    Test2::Log::Log4perl->start();

    $tlogger->error("my hair is on fire!");
    $logger->debug("ignore me");
    $logger->trace("ignore ignore ignore");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("my hair is on fire!");

    Test2::Log::Log4perl->end();
  },
  array {
      fail_events Ok => sub {
        call pass => 0;
      };
      event Diag => { message => qr/{message}.*{priority}/s };
  },
  "reset ignore_priority",
);

########################################################
# test that we can ignore everything

like(
  intercept {
    Test2::Log::Log4perl->start(
      ignore_priority => "everything",
    );

    $logger->debug("ignore me");
    $logger->trace("ignore ignore ignore");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("ignore with pleasure");
    $logger->fatal("ignore this finally");

    Test2::Log::Log4perl->end();
  },
  array {
      end;
  },
  "ignore_priority => everything triggers zero tests",
);

########################################################
# but they go back at the start of the next thing
#
like(
  intercept {
    Test2::Log::Log4perl->start();

    $logger->debug("ignore me");
    $logger->trace("ignore ignore ignore");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("ignore with pleasure");
    $logger->fatal("ignore this finally");

    Test2::Log::Log4perl->end();
  },
  array {
      fail_events Ok => sub {
        call pass => 0;
      };
      event Diag => { message => qr/Unexpected debug of type 'Foo'/s };
      event Diag => { message => qr/ignore me/s };
      end;
  },
  "reset ignore_priority",
);

########################################################
# test that we ignore some priorities forever

like(
  intercept {
    Test2::Log::Log4perl->start(
      # this should be overriden
      ignore_priority => "error",
    );

    Test2::Log::Log4perl->ignore_priority("warn");

    $tlogger->error("my hair is on fire!");
    $logger->debug("ignore me");
    $logger->trace("ignore ignore ignore");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("my hair is on fire!");

    Test2::Log::Log4perl->end();
  },
  array {
      event Ok => sub {
        call pass => 1;
      };
      end;
  },
  "global ignore_priority",
);

########################################################
# and they don't go back, the ignore priority
# should still be set

like(
  intercept {
    Test2::Log::Log4perl->start();

    $tlogger->error("my hair is on fire!");
    $logger->debug("ignore me");
    $logger->trace("ignore ignore ignore");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("my hair is on fire!");

    Test2::Log::Log4perl->end();
  },
  array {
      event Ok => sub {
        call pass => 1;
      };
      end;
  },
  "ignore_priority still set",
);
########################################################
# though we can turn them off with ignore nothing

like(
  intercept {
    Test2::Log::Log4perl->start();
    Test2::Log::Log4perl->ignore_priority("nothing");

    $tlogger->error("my hair is on fire!");
    $logger->debug("ignore me");
    $logger->trace("ignore ignore ignore");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("my hair is on fire!");

    Test2::Log::Log4perl->end();
  },
  array {
      fail_events Ok => sub {
        call pass => 0;
      };
      event Diag => { message => qr/{message}.*{priority}/s };
      end;
  },
  "ignore_priority nothing",
);

########################################################
# and that's still set next time

like(
  intercept {
    Test2::Log::Log4perl->start();

    $tlogger->error("my hair is on fire!");
    $logger->debug("ignore me");
    $logger->trace("ignore ignore ignore");
    $logger->info("ignore me too");
    $logger->warn("ignore me as well");
    $logger->error("my hair is on fire!");

    Test2::Log::Log4perl->end();
  },
  array {
      fail_events Ok => sub {
        call pass => 0;
      };
      event Diag => { message => qr/{message}.*{priority}/s };
      end;
  },
  "ignore_priority nothing persists",
);

########################################################
# and we can ignore everything

like(
  intercept {
    Test2::Log::Log4perl->start();
    Test2::Log::Log4perl->ignore_priority("everything");

    $logger->debug("ignore me");
    $logger->info("ignore me too");
    $logger->trace("ignore ignore ignore");
    $logger->warn("ignore me as well");
    $logger->error("ignore with pleasure");
    $logger->fatal("ignore this finally");

    Test2::Log::Log4perl->end();
  },
  array {
      end;
  },
  "ignore_priority everything makes zero tests",
);

########################################################
# and things are still ignored

like(
  intercept {
    Test2::Log::Log4perl->start();

    $logger->debug("ignore me");
    $logger->info("ignore me too");
    $logger->trace("ignore ignore ignore");
    $logger->warn("ignore me as well");
    $logger->error("ignore with pleasure");
    $logger->fatal("ignore this finally");

    Test2::Log::Log4perl->end();
  },
  array {
      end;
  },
  "ignore_priority everything persits",
);

########################################################
# and we can ignore nothing

like(
  intercept {
    Test2::Log::Log4perl->start();
    Test2::Log::Log4perl->ignore_priority("nothing");

    $tlogger->debug("don't ignore me");
    $tlogger->trace("no ignore no ignore no ignore");
    $tlogger->info("don't ignore me too");
    $tlogger->warn("don't ignore me as well");
    $tlogger->error("don't ignore with pleasure");
    $tlogger->fatal("don't ignore this finally");

    $logger->debug("don't ignore me");
    $logger->trace("no ignore no ignore no ignore");
    $logger->info("don't ignore me too");
    $logger->warn("don't ignore me as well");
    $logger->error("don't ignore with pleasure");
    $logger->fatal("don't ignore this finally");

    Test2::Log::Log4perl->end();
  },
  array {
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      end;
  },
  "ignore_priority nothing",
);

########################################################
# and we can ignore nothing
# and that remains set too

like(
  intercept {
    Test2::Log::Log4perl->start();

    $tlogger->debug("don't ignore me");
    $tlogger->trace("no ignore no ignore no ignore");
    $tlogger->info("don't ignore me too");
    $tlogger->warn("don't ignore me as well");
    $tlogger->error("don't ignore with pleasure");
    $tlogger->fatal("don't ignore this finally");

    $logger->debug("don't ignore me");
    $logger->trace("no ignore no ignore no ignore");
    $logger->info("don't ignore me too");
    $logger->warn("don't ignore me as well");
    $logger->error("don't ignore with pleasure");
    $logger->fatal("don't ignore this finally");

    Test2::Log::Log4perl->end();
  },
  array {
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      event Ok => { pass => 1 };
      end;
  },
  "ignore_priority persists",
);

done_testing;
