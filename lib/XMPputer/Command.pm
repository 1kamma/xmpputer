package XMPputer::Command;

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

sub new {
    my $cls = shift;
    my $conf = shift;
    my %args = @_;
    my $self = bless {}, $cls;
    $self->{unsolicited} = 0;
    foreach my $arg (qw(muc account)) {
        $self->{$arg} = $args{$arg} if $args{$arg};
    }
    return $self;
}

sub help {
    my $self = shift;
    my $params = shift;

    print STDERR "Warning: ".(ref $self)." is missing help\n";
    return undef;
}

sub ready {
    my $self = shift;
    return;
}

1;
