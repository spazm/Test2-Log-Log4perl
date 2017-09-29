package Test2::Log::Log4perl::Logger::Interception::JSON;
use base qw(Test2::Log::Log4perl::Logger::Interception);

use strict;
use warnings;

use Try::Tiny;
use JSON qw(from_json);

use Carp;
our @CARP_NOT = qw(Test2::Log::Log4perl);

#override _log_message to decode the json message
sub _log_message {
  my ($self, $msg) = @_;

  my $raw_message = $msg->{message};
  try {
    my $decoded_message = from_json($raw_message);
    $msg->{message}     = $decoded_message;
    $msg->{raw_message} = $raw_message;
  } catch {
    carp("Failed to decode message:$raw_message");
  };

  $self->SUPER::_log_message($msg);
};

1;
