package XMPputer::Command::Help;

use warnings;
use strict;

use parent "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*help(?:\s+.*)?/i) {
	return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    my @res;
    my $commands = $params->commands;
    foreach my $cmd (@{$commands->{cmds}}) {
	push @res, $cmd->help($params);
    }
    my $missing = scalar(grep {not defined $_} @res);
    @res = grep {$_} @res;
    if (@res) {
	@res = sort @res;
	unless (@res == 1 and $res[0] eq $self->help($params)) {
	    push @res, "(some commands are missing help)" if $missing;
	    return join("\n", @res);
	}
    }
    return "Sorry, I can't help you";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return 1;
}

sub name {
    return "help";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
	return "help - prints help";
    }
    return "";
}

1;
