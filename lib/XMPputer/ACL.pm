package XMPputer::ACL;

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

use List::Util qw(any);
use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;

sub new {
    my $cls = shift;
    my $self = bless {}, $cls;
    $self->read_file("/dev/null");
    return $self;
}

sub read_file {
    my $self = shift;
    my $file = shift;

    $self->{acl} = {'*' => []};
    open(ACL, "<$file") or die "can't read acl file";
    foreach my $acl (<ACL>) {
        my ($key, $value) = split /\s+/, $acl, 2;
        chomp($value);
        $self->{acl}{$key} //= [];
        push @{$self->{acl}{$key}}, $value;
    }
    close(ACL);
}

# if a user is allowed to run command
sub allow {
    my ($self, $command, $params) = @_;

    # everyone is allowed unsolicited commands
    if ($params->commands->get_command($command) and
        $params->commands->get_command($command)->{unsolicited}) {
        return 1;
    }

    $self->{acl}{$command} //= [];
    return any { 0
                   or $params->jid eq $_
                   or "*" eq $_
                   or ($params->room_member and $params->room_member eq $_)
                   or ($params->room_member and bare_jid($params->room_member)."/*" eq $_)
               } (@{$self->{acl}{$command}}, @{$self->{acl}{'*'}});
}

# all auths allowed to user
sub auths {
    my $self = shift;
    my $params = shift;

    my @commands;
    foreach my $command (keys %{$self->{acl}}) {
        push @commands, $command if $self->allow($command, $params);
    }

    return @commands;
}

1;
