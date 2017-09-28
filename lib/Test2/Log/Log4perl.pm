package Test2::Log::Log4perl;
use strict;
use warnings;

use 5.8.8;

use Test2::API qw/context/;

use Carp qw(croak);
use Scalar::Util qw(blessed);
use Log::Log4perl qw(:levels);

$Log::Log4perl::Logger::INITIALIZED = 1;
our $VERSION = '0.32';

=head1 NAME

Test2::Log::Log4perl - test log4perl

=head1 SYNOPSIS

  # setup l4p
  use Log::Log4Perl;
  # do your normal Log::Log4Perl setup here
  use Test2::Log::Log4perl;

  # get the loggers
  my $logger  = Log::Log4perl->get_logger("Foo::Bar");
  my $tlogger = Test2::Log::Log4perl->get_logger("Foo::Bar");

  # test l4p
  Test2::Log::Log4perl->start();

  # declare we're going to log something
  $tlogger->error("This is a test");

  # log that something
  $logger->error("This is a test");

  # test that those things matched
  Test2::Log::Log4perl->end("Test that that logs okay");

  # we also have a simplified version:
  {
    my $foo = Test2::Log::Log4perl->expect(['foo.bar.quux', warn => qr/hello/ ]);
    # ... do something that should log 'hello'
  }
  # $foo goes out of scope; this triggers the test.

=head1 DESCRIPTION

This module can be used to test that you're logging the right thing
with Log::Log4perl.  It checks that we get what, and only what, we
expect logged by your code.

The basic process is very simple.  Within your test script you get
one or more loggers from B<Test2::Log::Log4perl> with the C<get_logger> method
just like you would with B<Log::Log4perl>.  You're going to use these
loggers to declare what you think the code you're going to test should
be logging.

  # declare a bunch of test loggers
  my $tlogger = Test2::Log::Log4perl->get_logger("Foo::Bar");

Then, for each test you want to do you need to start up the module.

  # start the test
  Test2::Log::Log4perl->start();

This diverts all subsequent attempts B<Log::Log4perl> makes to log
stuff and records them internally rather than passing them though to
the Log4perl appenders as normal.

You then need to declare with the loggers we created earlier what
we hope Log4perl will be asked to log.  This is the same syntax as
Log::Log4perl uses, except if you want you can use regular expressions:

  $tlogger->debug("fish");
  $tlogger->warn(qr/bar/);

You then need to run your code that you're testing.

  # call some code that hopefully will call the log4perl methods
  # 'debug' with "fish" and 'warn' with something that contains 'bar'
  some_code();

We finally need to tell B<Test2::Log::Log4Perl> that we're done and it
should do the comparisons.

  # start the test
  Test2::Log::Log4perl->end("test name");

=head2 Methods

=over

=item get_logger($category)

Returns a new instance of Test2::Log::Log4perl that can be used to log
expected messages in the category passed.

=cut

sub get_logger
{
  my $class = shift;
  my $self = bless { category => shift }, $class;
  return $self;
}

=item Test2::Log::Log4perl->expect(%start_args, ['dotted.path', 'warn' => qr(this), 'warn' => qr(that)], ..)

Class convenience method. Used like this:

  { # start local scope
    my $foo = Test2::Log::Log4perl->expect(['foo.bar.quux', warn => qr/hello/ ]);
    # ... do something that should log 'hello'
  } # $foo goes out of scope; this triggers the test.

=cut

sub expect {
  my $class = shift;
  my (@start_args, @expects);
  for (@_) {
      if (ref($_) eq 'ARRAY') {
          push @expects, $_;
      }
      else {
          push @start_args, $_;
      }
  }
  $class->start(@start_args);
  my @loggers;
  for (@expects) {
      my $name = shift @$_;
      my $tlogger = $class->get_logger($name);
      # XXX: respect current loglevel
      while (my ($level, $what) = splice(@$_, 0, 2)) {
          $tlogger->$level($what);
      }
      push @loggers, $tlogger;
  }
  return \@loggers;
}


=item start

Class method.  Start logging.  When you call this method it temporarily
redirects all logging from the standard logging locations to the
internal logging routine until end is called.  Takes parameters to
change the behavior of this (and only this) test.  See below.

=cut

# convet a string priority into a digit one
sub _to_d
{
  my ($class, $priority) = @_;

  # check the priority is all digits
  if ($priority =~ /\D/)
  {
    if    (lc($priority) eq "everything") { $priority = $OFF }
    elsif (lc($priority) eq "nothing")    { $priority = $ALL }
    else  { $priority = Log::Log4perl::Level::to_priority(uc $priority) }
  }

  return $priority;
}

# the list of things we've stored so far
our @expected;
our @logged;

sub expected {
  my $class = shift;
  \@expected
}

sub clear_expected {
  my $class = shift;
  @expected = ();
  return;
}

# note, this will always be @Test2::Log::Log4perl::logged, even in subclass.
sub logged {
  my $class = shift;
  \@logged
}

sub clear_logged {
  my $class = shift;
  @logged = ();
}

sub reset_data {
  my $class = shift;
  $class->clear_expected();
  $class->clear_logged();
}

sub _set_ignore_priority {
  my ($class, %args) = @_;

  my $ignore_priority = $args{ignore_priority};

  if ($args{ignore_everything})
    { $ignore_priority = "everything" }
  if ($args{ignore_nothing})
    { $ignore_priority = "nothing" }
  if (defined $ignore_priority)
  {
    my $ignore_priority_d = $class->_to_d( $ignore_priority );
    $class->interception_class->set_temp("ignore_priority", $ignore_priority_d )
  };
}

sub _loggers {
  my $class = shift;
  values %$Log::Log4perl::Logger::LOGGERS_BY_NAME;
}

sub _turn_on_intercept_code {
  my $class = shift;
  foreach my $logger ($class->_loggers)
  {
    bless $logger, $class->interception_class;
  }
  return
}

sub _turn_off_intercept_code {
  my $class = shift;
  foreach my $logger ($class->_loggers)
  {
    bless $logger, $class->original_class
  }
}

sub start
{
  my $class = shift;
  my %args = @_;

  $class->reset_data();
  $class->interception_class->reset_temp;

  $class->_set_ignore_priority(%args);

  # turn on the interception code
  $class->_turn_on_intercept_code();
}

=item debug(@what)

=item info(@what)

=item warn(@what)

=item error(@what)

=item fatal(@what)

Instance methods.  String of things that you're expecting to log, at
the level you're expecting them, in what class.

=cut

sub _log_at_level
{
  my $self     = shift;
  my $priority = shift;
  my $message  = ref $_[0] ? shift : join '', grep defined, @_;

  push @expected, {
    category => $self->{category},
    priority => $priority,
    message  => $message,
  };
}

foreach my $level (qw(trace debug info warn error fatal))
{
  no strict 'refs';
  *{$level} = sub {
   my $class = shift;
   $class->_log_at_level($level, @_)
  }
}

=item end()

=item end($name)

Ends the test and compares what we've got with what we expected.
Switches logging back from being captured to going to wherever
it was originally directed in the config.

=cut


# eeek, the hard bit
sub end
{
  my $class = shift;
  my $name = shift || $class->test_name;

  my $ctx = context();

  $class->interception_class->set_temp("ended", 1);
  $class->_turn_off_intercept_code();

  unless ($class->test_all_messages($name, $class->logged, $class->expected)){
    $ctx->release();
    return 0
  };

  $ctx->ok(1, $name);
  $ctx->release();
  return 1;
}

sub test_name { "Log4perl test" }

sub test_all_messages {
  my ($class, $name, $all_logged, $all_expected) = @_;
  my $ctx = context();

  my $num = 0;
  while (@$all_logged) {

    $num++;

    my $logged   = shift @$all_logged;
    my $expected = shift @$all_expected;

    unless ($class->test_message($num, $name, $logged, $expected)) {
      $ctx->release();
      return 0
    }
  }
  unless ($class->test_extra_expected($name, @$all_expected)) {
    $ctx->release();
    return 0
  }

  $ctx->release();
  return 1;
}

sub test_message {
  my ($class, $num, $name, $logged, $expected ) = @_;
  my $ctx = context();

  # not expecting anything?
  unless ($expected)
  {
    $ctx->ok(0,$name);
    $ctx->diag("Unexpected $logged->{priority} of type '$logged->{category}':\n");
    $ctx->diag("  '$logged->{message}'");

    $ctx->release();
    return 0;
  }

  # was this message what we expected?
  # ...
  my %wrong = map { $_ => 1 }
                grep { !$class->_matches($logged->{ $_ }, $expected->{ $_ }) }
                qw(category message priority);
  if (%wrong)
  {
    $ctx->ok(0, $name);
    $ctx->diag("Message $num logged wasn't what we expected:");
    foreach my $thingy (qw(category priority message))
    {
      if ($wrong{ $thingy })
      {
        $ctx->diag(sprintf(q{ %8s was '%s'}, $thingy, $logged->{ $thingy }));
        if (ref($expected->{ $thingy }) && ref($expected->{ $thingy }) eq "Regexp")
          { $ctx->diag("     not like '$expected->{$thingy}'") }
        else
          { $ctx->diag("          not '$expected->{$thingy}'") }
      }
    }
    $ctx->diag(" (Offending log call from line $logged->{line} in $logged->{filename})");

    $ctx->release();
    return 0;
  }
  $ctx->release();
  return 1;
}

sub test_extra_expected {
  my ($class, $name, @expected) = @_;
  my $ctx = context();
  if (@expected)
  {
    $ctx->ok(0, $name);
    $ctx->diag("Ended logging run, but still expecting ".@expected." more log(s)");
    $ctx->diag("Expecting $expected[0]{priority} of type '$expected[0]{category}' next:");
    $ctx->diag("  '$expected[0]{message}'");
    $ctx->release();
    return 0;
  }
  $ctx->release();
  return 1;
}

# this is essentially a trivial implementation of perl 6's smart match operator
sub _matches
{
  my $class    = shift;
  my $got      = shift;
  my $expected = shift;

  use Test2::Compare qw/compare relaxed_convert/;

  my $delta = compare($got, $expected, \&relaxed_convert);
  # delta is a beautiful comparison object, and we downcast to a bool
  return !$delta;
}

=back

=head2 Ignoring All Logging Messages

Sometimes you're going to be testing something that generates a load
of spurious log messages that you simply want to ignore without
testing their contents, but you don't want to have to reconfigure
your log file.  The simplest way to do this is to do:

  use Test2::Log::Log4perl;
  Test2::Log::Log4perl->suppress_logging;

All logging functions stop working.  Do not alter the Logging classes
(for example, by changing the config file and use Log4perl's
C<init_and_watch> functionality) after this call has been made.

This function will be effectively a no-op if the environmental variable
C<NO_SUPPRESS_LOGGING> is set to a true value (so if your code is
behaving weirdly you can turn all the logging back on from the command
line without changing any of the code)

=cut

# TODO: What if someone calls ->start() after this then, eh?
# currently it'll test the logs and then stop suppressing logging
# is that what we want?  Because that's what'll happen.

sub suppress_logging
{
  my $class = shift;

  return if $ENV{NO_SUPPRESS_LOGGING};

  # tell this to ignore everything.
   foreach (values %$Log::Log4perl::Logger::LOGGERS_BY_NAME)
    { bless $_, $class->ignore_all_class }
}

=head2 Selectively Ignoring Logging Messages By Priority

It's a bad idea to completely ignore all messages.  What you probably
want to do is ignore some of the trivial messages that you don't
care about, and just test that there aren't any unexpected messages
of a set priority.

You can temporarily ignore any logging messages that are made by
passing parameters to the C<start> routine

  # for this test, just ignore DEBUG, INFO, and WARN
  Test2::Log::Log4perl->start( ignore_priority => "warn" );

  # you can use the levels constants to do the same thing
  use Log::Log4perl qw(:levels);
  Test2::Log::Log4perl->start( ignore_priority => $WARN );

You might want to ignore all logging events at all (this can be used
as quick way to not test the actual log messages, but just ignore the
output.

  # for this test, ignore everything
  Test2::Log::Log4perl->start( ignore_priority => "everything" );

  # contary to readability, the same thing (try not to write this)
  use Log::Log4perl qw(:levels);
  Test2::Log::Log4perl->start( ignore_priority => $OFF );

Or you might want to not ignore anything (which is the default, unless
you've played with the method calls mentioned below:)

  # for this test, ignore nothing
  Test2::Log::Log4perl->start( ignore_priority => "nothing" );

  # contary to readability, the same thing (try not to write this)
  use Log::Log4perl qw(:levels);
  Test2::Log::Log4perl->start( ignore_priority => $ALL );

You can also permanently effect what things are ignored with the
C<ignore_priority> method call.  This persists between tests and isn't
automatically reset after each call to C<start>.

  # ignore DEBUG, INFO and WARN for all future tests
  Test2::Log::Log4perl->ignore_priority("warn");

  # you can use the levels constants to do the same thing
  use Log::Log4perl qw(:levels);
  Test2::Log::Log4perl->ignore_priority($WARN);

  # ignore everything (no log messages will be logged)
  Test2::Log::Log4perl->ignore_priority("everything");

  # ignore nothing (messages will be logged reguardless of priority)
  Test2::Log::Log4perl->ignore_priority("nothing");

Obviously, you may temporarily override whatever permanent.

=cut

sub ignore_priority
{
  my $class = shift;
  my $p = $class->_to_d( shift);
  $class->interception_class->set_temp("ignore_priority", $p);
  $class->interception_class->set_perm("ignore_priority", $p);
}

sub ignore_everything
{
  my $class = shift;
  $class->ignore_priority($OFF);
}

sub ignore_nothing
{
  my $class = shift;
  $class->ignore_priority($ALL);
}

sub interception_class { "Log::Log4perl::Logger::Interception" }
sub ignore_all_class   { "Log::Log4perl::Logger::IgnoreAll"    }
sub original_class     { "Log::Log4perl::Logger"               }

sub DESTROY {
  return if $_[0]->interception_class->ended;
  goto $_[0]->can('end');
}

###################################################################################################

package Log::Log4perl::Logger::Interception;
use base qw(Log::Log4perl::Logger);
use Log::Log4perl qw(:levels);

our %temp;
our %perm;

sub reset_temp { %temp = () }
sub set_temp { my ($class, $key, $val) = @_; $temp{$key} = $val }
sub set_perm { my ($class, $key, $val) = @_; $perm{$key} = $val }
sub ended { my ($class) = @_; $temp{ended} }
# all the basic logging functions
foreach my $level (qw(trace debug info warn error fatal))
{
  no strict 'refs';

  # we need to pass the number to log
  my $level_int = Log::Log4perl::Level::to_priority(uc($level));
  *{"is_".$level} = sub { 1 };
  *{$level} = sub {
   my $self = shift;
   $self->log($level_int, @_)
  }
}

sub log
{
  my $self     = shift;
  my $priority = shift;
  my $message  = join '', grep defined, @_;

  # are we logging anything or what?
  if ($priority <= ($temp{ignore_priority} || 0) or
      $priority <= ($perm{ignore_priority} || 0))
    { return }

  # what's that priority called then?
  my $priority_name = lc( Log::Log4perl::Level::to_level($priority) );

  # find the filename and line
  my ($filename, $line);
  my $cur_filename = _cur_filename();
  my $level = 1;
  do {
    (undef, $filename, $line) = caller($level++);
  } while ($filename eq $cur_filename || $filename eq $INC{"Log/Log4perl/Logger.pm"});

 # prepare message
 my $msg = {
    category => $self->{category},
    priority => $priority_name,
    message  => $message,
    filename => $filename,
    line     => $line,
  };

  # log it
  $self->_log_message($msg);

  return;
}

sub _log_message {
  my ($self, $msg) = @_;
  push @Test2::Log::Log4perl::logged, $msg;
};

sub _cur_filename { (caller)[1] }

1;

package Log::Log4perl::Logger::IgnoreAll;
use base qw(Log::Log4perl::Logger);

# all the functions we don't want
foreach my $level (qw(trace debug info warn error fatal log))
{
  no strict 'refs';
  *{$level} = sub { return () }
}

=head1 BUGS

Logging methods don't return the number of appenders they've written
to (or rather, they do, as it's always zero.)

Changing the config file (if you're watching it) while this is testing
/ suppressing everything will probably break everything.  As will
creating new appenders, etc...

=head1 AUTHOR

  Andrew Grangaard <spazm@cpan.org>
  Chia-liang Kao <clkao@clkao.org>
  Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

  Copyright 2017 Andrew Grangaard all rights reserved.
  Copyright 2010 Chia-liang Kao all rights reserved.
  Copyright 2005 Fotango Ltd all rights reserved.

  Licensed under the same terms as Perl itself.

=cut

1;
