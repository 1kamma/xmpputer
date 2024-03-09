package XMPputer::Command::Roll;

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

use Games::Dice qw(roll roll_array);

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg, $return) = @_;

    if ($msg =~ m{^\s*roll(a?)\s+
                  ((?<count>\d{1,4})?[dD](?<type>\d{1,5}|%|F)(?:(?<sign>[-+xX*/bB])(?<offset>\d{1,5}))?)
                  \s*$}x
       ) {
        if ($return) {
            return $1, $2;
        } else {
            return $self;
        }
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if (my @match = $self->match($params->msg, 1)) {
        my ($array, $dice) = @match;
        if ($array) {
            my @throws = roll_array $dice;
            return join(" + ", @throws)." = ".List::Util::sum(@throws);
        } else {
            return roll $dice;
        }
    }

    return "Bad roll command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow("roll", $params);
}

sub name {
    return "roll";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
        return "roll <dice> - prints results of <dice> roll", "rolla <dice> - prints intermediate results of <dice> roll";
    }
    return "";
}

1;
