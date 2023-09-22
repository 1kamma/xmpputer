package XMPputer::Command::Help;

##############################################################################
#   XMPputer - very simple XMPP bot                                          #
#   Copyright (C) 2023 Yair Yarom                                            #
#                                                                            #
#   This program is free software: you can redistribute it and/or modify     #
#   it under the terms of the GNU General Public License as published by     #
#   the Free Software Foundation, either version 3 of the License, or        #
#   (at your option) any later version.                                      #
#                                                                            #
#   This program is distributed in the hope that it will be useful,          #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of           #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
#   GNU General Public License for more details.                             #
#                                                                            #
#   You should have received a copy of the GNU General Public License        #
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.   #
##############################################################################

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
