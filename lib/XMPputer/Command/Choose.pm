package XMPputer::Command::Choose;

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

use Math::Random::Discrete;

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*choose:.*[^\s,]+/i) {
        return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*choose\s*::?\s+(.*)$/i) {
        my @weights;
        my @choices;
        foreach my $choice (map {s/^\s*|\s*$//rg} split /,/, $1) {
            if ($choice =~ m/^(\d+):(.*)$/) {
                push @weights, $1;
                push @choices, $2;
            } else {
                push @weights, 1;
                push @choices, $choice;
            }
        }
        return Math::Random::Discrete->new(\@weights, \@choices)->rand;
    }

    return "Bad choose command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow("choose", $params);
}

sub name {
    return "choose";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
        return "choose: <option[s]> - choose an option (comma seperated, can be weighted - <weight>:<option>)";
    }
    return "";
}

1;
