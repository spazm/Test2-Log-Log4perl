package Test2::Log::Log4perl::Logger::IgnoreAll;

use strict;
use warnings;

use base qw(Log::Log4perl::Logger);

# all the functions we don't want
foreach my $level (qw(trace debug info warn error fatal log))
{
  no strict 'refs';
  *{$level} = sub { return () }
}

1;
