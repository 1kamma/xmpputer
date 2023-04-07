package XMPputer::Command::Echo;

use warnings;
use strict;

sub new {
    my $cls = shift;
    my $self = bless {}, $cls;
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*echo\s+[^\s]+/) {
	return $self;
    }
    return undef;
}

sub answer {
    my ($self, $msg, $from) = @_;

    if ($msg =~ m/^\s*echo\s+(.+)\s*$/) {
	return "$1";
    }

    return "Bad echo command\n";
}

sub allow {
    my ($self, %args) = @_;

    return $args{acl}->allow($args{jid}, "echo");
}

sub name {
    return "echo";
}

1;
