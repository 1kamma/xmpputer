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
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*echo\s+(.+)\s*$/) {
	return "$1";
    }

    return "Bad echo command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow($params->jid, "echo");
}

sub name {
    return "echo";
}

1;
