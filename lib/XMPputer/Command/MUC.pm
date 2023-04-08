package XMPputer::Command::MUC;

use warnings;
use strict;

use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;

sub new {
    my $cls = shift;
    my %args = @_;
    my $self = bless {}, $cls;
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*join\s+[^\s]+\s*$/i or $msg =~ m/^\s*leave(?:\s+[^\s]+\s*)?$/i) {
	return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*(join|leave)(?:\s+([^\s]+)\s*)?$/i) {
	my $what = $1;
	my $rjid = $2;
	if ($what eq "join") {
	    $params->muc->join_room($params->account->connection, $rjid, node_jid($params->account->jid));
	    return "Joined room $rjid";
	} else {
	    unless ($rjid) {
		$rjid = bare_jid($params->room_member) if $params->room_member;
	    }
	    unless ($rjid) {
		return "which room?\n";
	    }
	    my $room = $params->muc->get_room($params->account->connection, $rjid);
	    if ($room) {
		$room->send_part();
		#return "Left $rjid"; only outside room
		return "";
	    }
	    return "Not in room $rjid";
	}
    }

    return "Bad MUC command\n";
}

sub allow {
    my $self = shift;
    my $params = shift;

    return $params->acl->allow(lc($params->msg =~ s/^\s*(join|leave).*/$1/ir), $params);
}

sub name {
    my ($self, $msg) = @_;
    return lc($msg =~ s/^\s*([^\s]+).*/$1/ri);
}

1;
