package XMPputer::Command::Echo;

use warnings;
use strict;

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*echo\s+[^\s]+/i) {
	return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*echo\s+(.+)\s*$/i) {
	return "$1";
    }

    return "Bad echo command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow("echo", $params);
}

sub name {
    return "echo";
}

1;
