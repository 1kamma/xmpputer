package XMPputer::Command::Authorize;

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

use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*(de)?authorize\s+[^\s]+\s+[^\s]+\s*$/i) {
        return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*(de)?authorize\s+([^\s]+)\s+([^\s]+)\s*$/i) {
        my $deauth = $1;
        my $who = $2;
        my $what = $3;
        $params->acl->{acl}{$what} //= [];
        if ($params->room_member and index($who, "@") < 0) {
            $who = join("/", bare_jid($params->room_member), $who);
        }
        if ($deauth) {
            $params->acl->{acl}{$what} = [grep {$_ ne $who} @{$params->acl->{acl}{$what}}];
            return "$who deauthorized from $what";
        } else {
            push @{$params->acl->{acl}{$what}}, $who;
            return "$who authorized to $what";
        }
    }

    return "Bad (de)authorize command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow(lc($params->msg =~ s/^\s*((?:de)?authorize)\s+.*/$1/ri), $params);
}

sub help {
    my $self = shift;
    my $params = shift;
    my @res;

    my $params2 = $params->clone(msg => "authorize aaa bbb");
    if ($self->allow($params2)) {
        push @res, "authorize <user> <cmd> - authorize <user> to use <cmd>";
    }

    $params2 = $params->clone(msg => "deauthorize aaa bbb");
    if ($self->allow($params2)) {
        push @res, "deauthorize <user> <cmd> - remove <user> authorization to use <cmd>";
    }

    return @res ? @res : "";
}

sub name {
    my ($self, $msg) = @_;
    return "authorize" unless $msg;
    return lc($msg =~ s/^\s*([^\s]+).*/$1/ri);
}

1;

