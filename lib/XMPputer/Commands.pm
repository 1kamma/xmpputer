package XMPputer::Commands;

use warnings;
use strict;

use File::Find;
use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;

sub new {
    my $cls = shift;
    my $self = bless {}, $cls;
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    my %args = @_;
    my @cmds;

    $self->{cmds} = [];
    $self->{acl} = $args{acl};
    $self->{muc} = $args{muc};
    $self->{account} = $args{account};

    find({wanted => sub {
	      $_ =~ m/\.pm$/ and $File::Find::name =~ s,.*/XMPputer/Command/,, and push @cmds, $File::Find::name;
	  }},
	 grep {-d "$_"} map {"$_/XMPputer/Command/"} @INC);
    foreach my $cmdfile (@cmds) {
	(my $name) = $cmdfile =~ m/(.*)\.pm$/;
        next if index($cmdfile, ".#") == 0;
        eval {require "XMPputer/Command/$cmdfile"};
	die if ($@);
	my $cmd;
	eval "\$cmd = XMPputer::Command::${name}->new(muc => \$self->{muc}, account => \$self->{account}, acl => \$self->{acl})";
	next if ($@);
	push @{$self->{cmds}}, $cmd;
    }
}

sub answer {
    my ($self, $params) = @_;
    my $reply;
    my @commands;

    foreach my $cmd (@{$self->{cmds}}) {
	push @commands, $cmd->match($params->msg) // ();
    }

    unless (@commands) {
	print $params->room_member_withor_jid." not authorized\n";
	return "Not Authorized";
    } elsif (@commands > 1) {
	...
    } else {
	my $cmd = $commands[0];
	if ($cmd->allow($params)) {
	    return $commands[0]->answer($params);
	} else {
	    print $params->room_member_withor_jid." not authorized to ".$cmd->name($params->msg)."\n";
	    return "Not Authorized";
	}
    }
}

1;
