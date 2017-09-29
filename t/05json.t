#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0;
use Test2::Tools::Explain qw(explain);
use Test2::Tools::Exception qw/lives dies/;

use Log::Log4perl;
use Test2::Log::Log4perl;

my $interception_class = "Test2::Log::Log4perl::Logger::Interception::JSON";
Test2::Log::Log4perl->interception_class($interception_class);

my $logger     = Log::Log4perl->get_logger("Foo");
my $tlogger    = Test2::Log::Log4perl->get_logger("Foo");

# track test line number
my $line;

########################################################

like(
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error({ key => "value" });
    $logger->error('{"key":"value"}');
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
  "basic json ok t est"
);

########################################################

$line = undef;
like(
  intercept {
    Test2::Log::Log4perl->start();
    $tlogger->error({ key => "value" });
    $logger->error('"INVALIDJSON"');
    Test2::Log::Log4perl->end(); $line = __LINE__;
  },
  array {
    #event Ok => sub {
    #  call pass => 1;
    #  prop file => __FILE__;
    #  prop line => $line;
    #;
    #end;
  },
  "invalid json decode"
);

done_testing;
__END__

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
