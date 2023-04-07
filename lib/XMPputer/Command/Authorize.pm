package XMPputer::Command::Authorize;

use warnings;
use strict;

sub new {
    my $cls = shift;
    my %args = @_;
    my $self = bless {}, $cls;
    $self->{acl} = $args{acl};
    return $self;
}

sub match {
    my ($self, $msg) = @_;

    if ($msg =~ m/^\s*(de)?authorize\s+[^\s]+\s+[^\s]+\s*$/) {
	return $self;
    }
    return undef;
}

sub answer {
    my ($self, $msg, $from) = @_;

    if ($msg =~ m/^\s*(de)?authorize\s+([^\s]+)\s+([^\s]+)\s*$/) {
	my $deauth = $1;
	my $who = $2;
	my $what = $3;
	$self->{acl}{acl}{$what} //= [];
	if ($deauth) {
	    $self->{acl}{acl}{$what} = [grep {$_ ne $who} @{$self->{acl}{acl}{$what}}];
	    return "$who deauthorized from $what";
	} else {
	    push @{$self->{acl}{acl}{$what}}, $who;
	    return "$who authorized to $what";
	}
    }

    return "Bad (de)authorize command\n";
}

sub allow {
    my ($self, %args) = @_;

    return $args{acl}->allow($args{jid}, "echo");
}

sub name {
    my ($self, $msg) = @_;
    return $msg =~ s/^\s*([^\s]+).*/$1/r;
}

1;

