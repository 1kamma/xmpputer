package XMPputer::Command::Meow;

use warnings;
use strict;

use utf8;

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*meow\s*$/i) {
	return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*meow\s*$/i) {
	my @cats = ('🐱','😺','😽','😸','😻');
	return $cats[rand(@cats)];
    }

    return "Bad meow command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return 1;
    #return $params->acl->allow("meow", $params);
}

sub name {
    return "meow";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
	return "meow";
    }
    return "";
}

1;
