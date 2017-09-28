#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain qw(explain);
use Test2::Tools::Exception qw/lives dies/;

use Log::Log4perl;
use Test2::Log::Log4perl;

# configure two loggers:
my $logger     = Log::Log4perl->get_logger("Foo");
my $logger_bar = Log::Log4perl->get_logger("Bar");

# configure two log watchers
my $tlogger    = Test2::Log::Log4perl->get_logger("Foo");
my $t2logger   = Test2::Log::Log4perl->get_logger("Bar");

# track test line number
my $line;

########################################################

like(
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on fire!");
    $logger->error("my hair is on fire!");
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    event Ok => sub {
      call pass => 1;
      prop file => __FILE__;
      prop line => $line;
    };
    end;
  },
  "basic ok test"
);

########################################################

like(
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on fire!");
    $logger->error("my hair is on ", "fire!");
    Test2::Log::Log4perl->end();
  },
  array {
    event Ok => {pass => 1};
    end;
  },
  "basic ok test"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $logger->error("my hair is on ", "fire!");
    Test2::Log::Log4perl->end();
  },
  array {
    fail_events Ok => { pass => 0 };
    event Diag => { message => qr/Unexpected error of type 'Foo'/ };
    event Diag => { message => qr/my hair is on fire!/ };
    end;
  },
  "not expecting anything"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on fire!");
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    fail_events Ok => sub {
      call pass => 0;
      prop file => __FILE__;
      prop line => $line;
    };
    event Diag => { message => qr/expecting 1 more log\(s\)/ };
    event Diag => { message => qr/Expecting error of type 'Foo'/ };
    event Diag => { message => qr/my hair is on fire!/ };
    end;
  },
  "expecting but not getting anything"
);

########################################################
#
like (
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on fire!");
    $logger->error("your hair is on fire!");
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    fail_events Ok => sub {
      call pass => 0;
      prop file => __FILE__;
      prop line => $line;
    };
    event Diag => { message => qr/PATH.*GOT.*OP.*CHECK.*\n.*message.*your hair.*eq.*my hair/s };
    end;
  },
  "getting wrong message"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on fire!");
    $logger->warn("my hair is on fire!");
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    fail_events Ok => sub {
      call pass => 0;
      prop file => __FILE__;
      prop line => $line;
    };
    event Diag => { message => qr/PATH.*GOT.*OP.*CHECK.*\n.*priority.*warn.*eq.*error/s };
    end;
  },
  "getting wrong priority"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $t2logger->error("my hair is on fire!");
    $logger->error("my hair is on fire!");
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    fail_events Ok => sub {
      call pass => 0;
      prop file => __FILE__;
      prop line => $line;
    };
    event Diag => { message => qr/PATH.*GOT.*OP.*CHECK.*\n.*category.*Foo.*eq.*Bar/s };
    end;
  },
  "getting wrong category"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $t2logger->error("my hair is on fire!");
    $logger->warn("your hair is on fire!");
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    fail_events Ok => sub {
      call pass => 0;
      prop file => __FILE__;
      prop line => $line;
    };
    event Diag => { message => qr/PATH.*GOT.*OP.*CHECK.*\n.*category.*Foo.*eq.*Bar.*message.*your hair.*my hair.*priority.*warn.*error/s };
    end;
  },
  "getting it all wrong"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->fatal("my hair is on fire!");
    $logger->fatal("my hair is on fire!");
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    event Ok => sub {
      call pass => 1;
      prop file => __FILE__;
      prop line => $line;
    };
    end;
  },
  "fatal"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->fatal("my hair is on fire!");
    like(
      dies {$logger->logdie("my hair is on fire!")},
      qr/my hair is on fire!/,
      "logdie dies"
    );
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    event Ok => {pass => 1};
    event Ok => sub {
      call pass => 1;
      prop file => __FILE__;
      prop line => $line;
    };
    end;
  },
  "logdie"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on ", "fire!");
    $logger->error("my hair is on fire!");
    $logger_bar->error("BAR BAR BAR"); # all categories are watched
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    event Ok => sub {
      call pass => 1;
      prop file => __FILE__;
      prop line => $line;
      end;
    };
    fail_events Ok => sub {
      call pass => 0;
      prop file => __FILE__;
      prop line => $line;
      end;
    };
    event Diag => { message => qr/Unexpected error of type 'Bar'/ };
    event Diag => { message => qr/BAR BAR BAR/};
    end;
  },
  "watch all categories"
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->watch_category("Foo");
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on ", "fire!");
    $logger->error("my hair is on fire!");
    $logger_bar->error("BAR BAR BAR");  # This category is ignored
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    event Ok => sub {
      call pass => 1;
      prop file => __FILE__;
      prop line => $line;
      end;
    };
    end;
  },
  "watch only Foo "
);

########################################################

like (
  intercept {
    Test2::Log::Log4perl->watch_category("Foo");
    Test2::Log::Log4perl->watch_category("Bar");
    Test2::Log::Log4perl->start();
    $tlogger->error("my hair is on ", "fire!");
    $logger->error("my hair is on fire!");
    $logger_bar->error("BAR BAR BAR"); # explicitly watching Bar
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    event Ok => sub {
      call pass => 1;
      prop file => __FILE__;
      prop line => $line;
      end;
    };
    fail_events Ok => sub {
      call pass => 0;
      prop file => __FILE__;
      prop line => $line;
      end;
    };
    event Diag => { message => qr/Unexpected error of type 'Bar'/ };
    event Diag => { message => qr/BAR BAR BAR/};
    end;
  },
  "watch Foo and Bar "
);

########################################################

done_testing;
