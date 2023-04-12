package XMPputer::Command::Authorize;

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

sub name {
    my ($self, $msg) = @_;
    return lc($msg =~ s/^\s*([^\s]+).*/$1/ri);
}

1;

