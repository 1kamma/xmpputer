package XMPputer::Command::MUC;

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

    my ($cmd, $room) = $params->msg =~ m/^\s*(join|leave)(?:\s+([^\s]+))?\s*$/;
    $cmd = lc($cmd);
    $room = bare_jid($params->room_member) if not $room and $params->room_member;

    return (0
	    or $params->acl->allow($cmd, $params)
	    or ($room and $params->acl->allow("$cmd/$room", $params))
	   );
}

sub help {
    my $self = shift;
    my $params = shift;
    my @res;
    my $have_join = 0;
    my $have_leave = 0;

    my @cmds = $params->acl->auths($params);
    foreach my $cmd (@cmds) {
	if ($cmd eq "join") {
	    push @res, "join <room> - join <room>";
	    $have_join = 1;
	} elsif ($cmd =~ m/^join\/(.*)/) {
	    push @res, "join $1 - join $1";
	} elsif ($cmd eq "leave") {
	    push @res, "leave <room> - leave <room>";
	    $have_leave = 1;
	} elsif ($cmd =~ m/^leave\/(.*)/) {
	    push @res, "leave $1 - leave $1";
	}
    }

    if ($have_join) {
	@res = grep {$_ !~ m/^join/ or $_ =~ m/^join <room>/} @res
    }
    if ($have_leave) {
	@res = grep {$_ !~ m/^leave/ or $_ =~ m/^leave <room>/} @res
    }

    if ($params->room_member) {
	my $rjid = bare_jid($params->room_member);
	if ($have_leave or grep {$_ eq "leave/$rjid"} @cmds) {
	    @res = grep {$_ !~ m/^leave $rjid /} @res;
	    push @res, "leave - leave this room ($rjid)";
	}
    }

    return @res ? @res : "";
}

sub name {
    my ($self, $msg) = @_;
    return "muc" unless $msg;
    return lc($msg =~ s/^\s*([^\s]+).*/$1/ri);
}

1;
