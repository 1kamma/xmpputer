package XMPputer::Command;

use warnings;
use strict;

sub new {
    my $cls = shift;
    my $self = bless {}, $cls;
    return $self;
}

sub help {
    my $self = shift;
    my $params = shift;

    print STDERR "Warning: ".(ref $self)." is missing help\n";
    return undef;
}

1;
