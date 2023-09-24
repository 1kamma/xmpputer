package XMPputer::Command::Tell;

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

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*tell\s+[^\s]+\s+[^\s].*/i) {
        return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*tell\s+([^\s]+)\s+(?:(to)\s+)?([^\s].*)$/i) {
        my ($whom, $to, $what) = ($1,$2,$3);
        $to //= "";
        my $contact = $params->account->connection->get_roster->get_contact($whom);
        if ($contact) {
            $contact->make_message(type => 'chat')->add_body($what)->send;
            return "told him!";
        } else {
            my $room = $params->muc->get_room($params->account->connection, $whom);
            if ($room) {
                $room->make_message(body => "$what")->send;
                return "told them!";
            }
        }
        return "$whom not on my contact list" unless $contact;
    }

    return "Bad tell command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow("tell", $params);
}

sub name {
    return "tell";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
        return "tell <user> to? <message> - prints <message> to <user>";
    }
    return "";
}

1;
