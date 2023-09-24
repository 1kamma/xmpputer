package XMPputer::Commands::Parameters;

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

use strict;
use warnings;

use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;

use Clone;

sub new {
    my $cls = shift;
    my $self = bless {}, $cls;
    my %args = @_;
    foreach my $arg (keys %args) {
        $self->{"_$arg"} = $args{$arg};
    }
    return $self;
}

sub clone {
    my $self = shift;
    my %args = @_;

    my $that = Clone::clone($self);
    foreach my $arg (keys %args) {
        $that->{"_$arg"} = $args{$arg};
    }
    return $that;
}

sub msg {
    my $self = shift;
    return $self->{_msg};
}

sub from {
    my $self = shift;
    return $self->{_from};
}

sub jid {
    my $self = shift;
    return $self->{_jid} if $self->{_jid};
    $self->{_jid} = bare_jid($self->from);
    return $self->{_jid};
}

sub acl {
    my $self = shift;
    return $self->{_acl};
}

sub room_member {
    my $self = shift;
    return $self->{_room_member};
}

sub muc {
    my $self = shift;
    return $self->{_muc};
}

sub account {
    my $self = shift;
    return $self->{_account};
}

sub commands {
    my $self = shift;
    return $self->{_commands};
}

sub unsolicited {
    my $self = shift;
    return $self->{_unsolicited};
}

sub room_member_withor_jid {
    my $self = shift;
    if ($self->room_member) {
        return $self->room_member." (".$self->jid.")";
    } else {
        return $self->jid
    }
}

1;
