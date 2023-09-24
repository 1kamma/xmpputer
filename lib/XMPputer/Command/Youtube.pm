package XMPputer::Command::Youtube;

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

use JSON;
use LWP::UserAgent;

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    $self->{unsolicited} = 1;
    $self->{ua} = LWP::UserAgent->new;
    $self->{ua}->agent("xmpputer");
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    foreach my $line (split /\n/, $msg) {
        next if $line =~ m/^>/;
        if ($line =~ m,https?://(?:www\.)?youtube.com/watch\?(?:v=|.*?\&v=)[a-zA-Z0-9_-]*,
            or
            $line =~ m,https?://(?:www\.)?youtube.com/shorts/[a-zA-Z0-9_-]*,) {
            return $self;
        }
    }

    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    my $id;
    my $reply = "";
    my $short = 0;
    foreach my $line (split /\n/, $params->msg) {
        next if $line =~ m/^>/;
        unless ($id) {
            if ($line =~ m,https?://(?:www\.)?youtube.com/watch\?(?:v=|.*?\&v=)([a-zA-Z0-9_-]*),) {
                $id = $1;
                $short = 0;
            } elsif ($line =~ m,https?://(?:www\.)?youtube.com/shorts/([a-zA-Z0-9_-]*),) {
                $id = $1;
                $short = 1;
            }
        }
    }

    if ($id) {
        my $title;
        print "Checking title for youtube $id\n";
        my $response = $self->{ua}->get("https://noembed.com/embed?url=https://www.youtube.com/watch?v=${id}");
        if ($response->is_success) {
            my $raw = $response->decoded_content;
            my $content;
            eval {$content = decode_json(Encode::encode_utf8($raw))};
            if ($content and $content->{title}) {
                if ($short) {
                    $reply .= "https://www.youtube.com/watch?v=$id\n";
                }
                $reply .= $content->{title};
                return $reply;
            } else {
                $reply .= "There's a youtube link there, but I can't seem to find the title";
                return $reply;
            }
        }

        return "";
    }

    return "Bad youtube command";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow("youtube", $params);
}

sub name {
    return "youtube";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
        return "youtube (unsolicited) - prints the youtube title";
    }
    return "";
}

1;
