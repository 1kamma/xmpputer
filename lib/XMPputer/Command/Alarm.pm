package XMPputer::Command::Alarm;

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

use List::Util qw(min max);
use Date::Manip;
use AnyEvent::XMPP::Util qw/bare_jid/;

use base "XMPputer::Command";

sub new {
    my $cls = shift;
    my $self = $cls->SUPER::new(@_);
    $self->{alarms} = [];
    $self->{timer} = undef;
    $self->{lasttimer} = undef;
    $self->{dm} = Date::Manip::Date->new();
    $self->{dm}->config("setdate" => "zone,Asia/Jerusalem");

    return $self;
}

sub match {
    my ($self, $msg, $return) = @_;

    if ($msg =~ m/^\s*remind\s+(me|all|us)\s+to\s+(.*?)$/i) {
        if ($return) {
            return $1, $2;
        } else {
            return $self;
        }
    }
    return undef;
}

sub create_timer {
    my $self = shift;
    my $minwhen = min(map {$_->{when}} @{$self->{alarms}});

    # no timer on recursive or initial
    if (not $self->{timer}
        or
        $minwhen < $self->{lasttimer}) {

        # if minwhen in the past somehow
        my $delta = max(0, $minwhen - time());

        my $timer = AnyEvent->timer (
                                     after => $delta,
                                     cb => sub {
                                         my $now = time();
                                         foreach my $alarm (grep {$_->{when} <= $now} @{$self->{alarms}}) {
                                             print "alarm: $alarm->{whom}: $alarm->{content}\n";

                                             my $contact = $alarm->{params}->account->connection->get_roster->get_contact($alarm->{whom});
                                             my $sent;
                                             if ($contact) {
                                                 $contact->make_message(type => 'chat')->add_body("Don't forget to $alarm->{content}")->send;
                                                 $sent = 1;
                                             } else {
                                                 my $room = $alarm->{params}->muc->get_room($alarm->{params}->account->connection, $alarm->{whom});
                                                 if ($room) {
                                                     my $prefix = "Don't";
                                                     if ($alarm->{whom} =~ m/\/(.*)$/) {
                                                         $prefix = "$1, don't";
                                                     }
                                                     $room->make_message(body => "$prefix forget to $alarm->{content}")->send;
                                                     $sent = 1;
                                                 }
                                             }
                                             print "Failed to send alarm to $alarm->{whom}\n" unless $sent;
                                         }
                                         $self->{alarms} = [grep {$_->{when} > $now} @{$self->{alarms}}];
                                         $self->{timer} = undef;
                                         $self->{lasttimer} = undef;
                                         if (@{$self->{alarms}}) {
                                             $self->create_timer();
                                         }
                                     },
                                    );

        $self->{timer} = $timer;
        $self->{lasttimer} = $minwhen;
        print "created timer\n";
    }
}

sub answer {
    my $self = shift;
    my $params = shift;

    if (my @match = $self->match($params->msg, 1)) {
        my ($whom, $whatwhen) = @match;
        my $what = "";
        my $when;
        my $lastsp = "";
        my $date = $self->{dm}->new_date();

        if ($params->room_member) {
            if (lc($whom) eq lc("me")) {
                $whom = $params->room_member;
            } else {
                $whom = bare_jid($params->room_member);
            }
        } else {
            $whom = $params->jid;
        }

        # otherwise "at 7" will fail, but "Nov. 7" should still work
        if ($whatwhen =~ m/\sat\s+\d+\s*$/i) {
            $whatwhen .= ":00";
        }

        while (1) {
            if ($whatwhen =~ m/^([^\s]+)(\s+)(.*)$/) {
                $what .= $lastsp.$1;
                $lastsp = $2;
                $when = $3;
                unless ($date->parse($when)) {
                    last;
                } else {
                    $whatwhen = $when;
                    next;
                }
            }
            last;
        }

        if ($date->err()) {
            return $date->err();
        }

        my $delta = $date->printf("%s") - $self->{dm}->new_date("now")->printf("%s");
        return "alarm command in the past" if ($delta < 0);

        my $swhen = time() + $delta;
        push @{$self->{alarms}}, {when => $swhen,
                                  content => $what,
                                  whom => $whom,
                                  params => $params,
                                 };

        $self->create_timer();

        my @responses = (
                         "Affirmative",
                         "All right",
                         "Alright",
                         "Alrighty",
                         "As you say",
                         "As you wish",
                         "Aye aye",
                         "Certainly",
                         "Confirmed",
                         "Fine",
                         "I'll do my best",
                         "If I must",
                         "No problem",
                         "Of course",
                         "Okay",
                         "Righto",
                         "Roger",
                         "Sure thing",
                         "Sure",
                         "Will do",
                         "Yes my liege",
                         "Yes sir",
                         "OK",
                        );
        my $response = $responses[rand(@responses)];
        $date->convert("Asia/Jerusalem");
        if ($delta < 60 * 60) {
            return $date->printf("$response");
        } else {
            return $date->printf("$response, I'll remind you at %Y-%m-%dT%T");
        }
    }

    return "Bad alarm command";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow("alarm", $params);
}

sub name {
    return "alarm";
}

sub help {
    my $self = shift;
    my $params = shift;

    if ($self->allow($params)) {
        return "remind (me|us|all) to X (at Y|in Z)";
    }
    return "";
}

1;
