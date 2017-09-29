package Test2::Log::Log4perl::Logger::Interception;

use strict;
use warnings;

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
  Test2::Log::Log4perl->log($msg);
};

sub _cur_filename { (caller)[1] }

1;
