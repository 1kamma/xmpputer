package XMPputer::Command::Dict;

use warnings;
use strict;

use base "XMPputer::Command";

use Net::Dict;

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*define:?\s+[^\s]+/i) {
	return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*define:?\s+(.+)\s*$/i) {
	my $dict = Net::Dict->new('dict.org');
	my $defines = $dict->define($1);
	if ($defines and @$defines) {
	    return $defines->[0][1];
	}
	return "Don't know about that...";
    }

    return "Bad define command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow("define", $params);
}

sub name {
    return "define";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
	return "define: <something> - defines <something>";
    }
    return "";
}

1;
