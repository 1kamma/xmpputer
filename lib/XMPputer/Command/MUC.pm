package XMPputer::Command::MUC;

use warnings;
use strict;

use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;

sub new {
    my $cls = shift;
    my %args = @_;
    my $self = bless {}, $cls;
    $self->{muc} = $args{muc};
    $self->{account} = $args{account};
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*(?:join|leave)\s+[^\s]+/) {
	return $self;
    }
    return undef;
}

sub answer {
    my $self = shift;
    my $params = shift;

    if ($params->msg =~ m/^\s*(join|leave)\s+([^\s]+)\s*$/) {
	my $what = $1;
	my $rjid = $2;
	if ($what eq "join") {
	    $self->{muc}->join_room($self->{account}->connection, $rjid, node_jid($self->{account}->jid));
	    return "Joined room $rjid";
	} else {
	    my $room = $self->{muc}->get_room($self->{account}->connection, $rjid);
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

    return $params->acl->allow($params->jid, $params->msg =~ s/^\s*(join|leave).*/$1/r);
}

sub name {
    my ($self, $msg) = @_;
    return $msg =~ s/^\s*([^\s]+).*/$1/r;
}

1;
