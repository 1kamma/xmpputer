#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use List::Util qw(any);
use Sys::Hostname;
use Getopt::Long;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;

binmode STDOUT, ":utf8";

# vars
my $conffile = "/etc/xmpputer/xmpputer.conf";
my $aclfile = "/etc/xmpputer/acl";
my $jid = 'root@localhost';
my $pw;
my @rooms;
my $in_jid;
my $in_pw;
my $in_room;
my $in_aclfile;
my $pwfile;
my $debug;

# args
unless (GetOptions("c|conf=s" 	  => \$conffile,
		   "j|jid=s"  	  => \$in_jid,
		   "p|password=s" => \$in_pw,
		   "r|room=s"     => \$in_room,
		   "aclfile=s"    => \$in_aclfile,
		   "debug!"       => \$debug,
		  )) {
    print STDERR "xmpputer [options]\n";
    print STDERR "-c conf      - $conffile\n";
    print STDERR "-j jid       - root\@localhost\n";
    print STDERR "-p password  - password\n";
    print STDERR "-r room      - room\@conference.localhost\n";
    print STDERR "-acl aclfile - $aclfile\n";
}
-e "$conffile" or die "$conffile doesn't exists";

# conf
open(CONF, "$conffile") or die "Can't open $conffile";
foreach my $line (<CONF>) {
    chomp($line);
    $line =~ s/#.*//;
    next if $line =~ m/^\s*$/;
    if ($line =~ m/^\s*jid\s*=\s*(.*)\s*$/) {
	$jid = $1;
    } elsif ($line =~ m/^\s*passwordfile\s*=\s*(.*)\s*$/) {
	$pwfile = $1;
    } elsif ($line =~ m/^\s*password\s*=\s*(.*)\s*$/) {
	$pw = $1;
    } elsif ($line =~ m/^\s*room\s*=\s*(.*)\s*$/) {
	push @rooms, $1;
    } elsif ($line =~ m/^\s*aclfile\s*=\s*(.*)\s*$/) {
	$aclfile = $1;
    } else {
	print STDERR "Bad conf line: $line\n";
    }
}
close(CONF);

# overwrite with args
$jid = $in_jid if $in_jid;
$pw = $in_pw if $in_pw;
if (not $pw and $pwfile) {
    open(PASSWORD, "<$pwfile") or die "can't read password file";
    $pw = <PASSWORD>;
    close(PASSWORD);
}
push @rooms, $in_room if $in_room;

my %acl;
open(ACL, "<$aclfile") or die "can't read acl file";
foreach my $acl (<ACL>) {
    my ($key, $value) = split /\s+/, $acl, 2;
    chomp($value);
    $acl{$key} //= [];
    push @{$acl{$key}}, $value;
}
close(ACL);

my $cv      = AnyEvent->condvar;
my $cl      = AnyEvent::XMPP::Client->new(debug => $debug);
my $disco   = AnyEvent::XMPP::Ext::Disco->new;
my $version = AnyEvent::XMPP::Ext::Version->new;
my $muc     = AnyEvent::XMPP::Ext::MUC->new (disco => $disco);

$version->set_name    ("xmpputer");
$version->set_version ("0.1");
$version->set_os      (`uname -s`);

$cl->add_extension ($disco);
$cl->add_extension ($version);
$cl->add_extension ($muc);

my $hostname = hostname =~ s/\..*//r;
#$cl->set_presence (undef, "alive?", 1);

$cl->add_account($jid, $pw, undef, undef, {resource => "$hostname"});
my $account = $cl->get_account($jid);

$cl->reg_cb (
	     session_ready => sub {
		 my ($cl, $acc) = @_;
		 print "session ready (".$acc->jid.")\n";
		 foreach my $room (@rooms) {
		     $muc->join_room($acc->connection, $room, node_jid($acc->jid));
		 }

		 $muc->reg_cb (
			       message => sub {
				   my ($cl, $room, $msg, $is_echo) = @_;
				   return unless $msg;
				   #print "got $msg in ".$room->jid."\n";
				   return if $is_echo;
				   return if $msg->is_delayed;
				   # my $mynick = res_jid ($room->nick_jid);
				   if ($msg->any_body =~ /^\s*\Qcomputer\E:\s+(.*?)\s*$/) {
				       print "room message: \"$msg\" from \"".res_jid($msg->from)."\" in \"".$room->jid."\"\n";
				       my $from = $room->get_user(res_jid($msg->from))->real_jid;
				       my $reply = answer($1, $from);
				       if ($reply) {
					   my $repl = $msg->make_reply;
					   $repl->add_body($reply);
					   $repl->send;
				       }
				   }
			       },

			       enter => sub {
				   my ($cl, $room, $user) = @_;
				   #use Data::Dumper; print Dumper([map {ref $_} @_]);
				   print "entered (".res_jid($user->jid)." in ".$room->jid.")\n";
			       },

			       error => sub {
				   my ($cl, $acc, $error) = @_;
				   warn "Error encountered: ".$error->string."\n";
				   $cv->broadcast;
			       },
			      );
	     },

	     message => sub {
		 my ($cl, $acc, $msg) = @_;

		 print "message: '".$msg->any_body."' from '".$msg->from."'\n";
		 my $reply = answer($msg->any_body, $msg->from);
		 if ($reply) {
		     my $repl = $msg->make_reply;
		     $repl->add_body($reply);
		     $repl->send;
		 }
	     },

	     contact_request_subscribe => sub {
		 my ($cl, $acc, $roster, $contact) = @_;
		 print "subscribed by ".$contact->jid."\n";
		 $contact->send_subscribed();
	     },

	     error => sub {
		 my ($cl, $acc, $error) = @_;
		 warn "Error encountered: ".$error->string."\n";
		 $cv->broadcast;
	     },

	     #   disconnect => sub {
	     #      warn "Got disconnected: [@_]\n";
	     #      $j->broadcast;
	     #   },
	    );

$cl->start;
$cv->wait;

sub answer {
    my ($msg, $from) = @_;
    my $jid = bare_jid($from);
    my $command;

    # echo
    if ($msg =~ m/^\s*echo\s+(.+)\s*$/) {
	my $echo = $1;
	$command = "echo";
	if (acl($jid, $command)) {
	    return "$echo";
	}
    }

    # leave
    if ($msg =~ m/^\s*leave\s+(.+)\s*$/) {
	my $rjid = $1;
	my $command = "leave";
	if (acl($jid, $command)) {
	    my $room = $muc->get_room($account->connection, $rjid);
	    if ($room) {
		$room->send_part();
		#return "Left $rjid";
		return "";
	    }
	    return "Not in room $rjid";
	}
    }

    # join
    if ($msg =~ m/^\s*join\s+(.+)\s*$/) {
	my $rjid = $1;
	my $command = "join";
	if (acl($jid, $command)) {
	    $muc->join_room($account->connection, $rjid, node_jid($account->jid));
	    return "Joined room $rjid";
	}
    }

    # authorize
    # deauthorize
    # roll
    # chat

    # nothing
    print "$jid not authorized";
    print " to \"$command\"" if $command;
    print "\n";
    return "Not Authorized";
}

sub acl {
    my $jid = shift;
    my $command = shift;
    $acl{$command} //= [];
    $acl{ALL} //= [];
    return any {$jid eq $_ or "ALL" eq $_} (@{$acl{$command}}, @{$acl{ALL}});
}
