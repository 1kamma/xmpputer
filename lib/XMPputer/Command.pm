package XMPputer::Command;

use warnings;
use strict;

sub new {
    my $cls = shift;
    my $self = bless {}, $cls;
    return $self;
}

1;
