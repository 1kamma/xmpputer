#!/usr/bin/env perl

use utf8;
use strict;
use warnings;

use List::Util qw(any);
use Games::Dice qw(roll roll_array);
use Getopt::Long;
use Sys::Hostname;
use AnyEvent::XMPP::Util qw/node_jid res_jid split_jid bare_jid/;
use AnyEvent::XMPP::Client;
use AnyEvent::XMPP::Ext::MUC;
use AnyEvent::XMPP::Ext::Disco;
use AnyEvent::XMPP::Ext::Version;

use XMPputer::ACL;
use XMPputer::Commands;
use XMPputer::Commands::Parameters;

$| = 1;
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
my $mypriority = int(rand() * 255) - 128;
$cl->set_presence("chat", "on-line", $mypriority);

#$cl->add_account($jid, $pw, undef, undef, {resource => "$hostname.".int(rand()*1000)});
$cl->add_account($jid, $pw, undef, undef, {resource => "$hostname"});
my $account = $cl->get_account($jid);

my $acl = XMPputer::ACL->new();
my $commands = XMPputer::Commands->new();
$acl->read_file($aclfile);

$cl->reg_cb (
	     session_ready => sub {
		 my ($cl, $acc) = @_;
		 print "session ready (".$acc->jid.", p: $mypriority)\n";

		 # subscribe to me (don't know if this works)
		 $acc->connection->get_roster->get_own_contact->send_subscribe();

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
				   if ($msg->any_body =~ /^(\s*\Qcomputer\E:\s+)?(.*?)\s*$/s) {
				       my ($unsolicited, $text) = (($1 ? 0 : 1), $2);
				       print "room message ".($unsolicited ? "(unsolicited)" : "").": \"$msg\" from \"".res_jid($msg->from)."\" in \"".$room->jid."\"\n" unless $unsolicited;
				       my $params = XMPputer::Commands::Parameters->new(msg => $text,
											from => $room->get_user(res_jid($msg->from))->real_jid,
											acl => $acl,
											muc => $muc,
											account => $account,
											room_member => $msg->from,
											commands => $commands,
											unsolicited => $unsolicited,
										       );
				       my $reply = $commands->answer($params);
				       if ($reply) {
					   print "room message ".($unsolicited ? "(unsolicited)" : "").": \"$msg\" from \"".res_jid($msg->from)."\" in \"".$room->jid."\"\n" if $unsolicited;
					   my $repl = $msg->make_reply;
					   $repl->add_body(join("\n", ("> ".$params->msg, $reply)));
					   $repl->send;
					   print "replied (to ".$repl->to."): $reply\n";
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
				   warn "MUC Error encountered: ".$error->string."\n";
				   $cv->broadcast;
			       },
			      );
	     },

	     presence_update => sub {
		 my ($cl, $acc, $roster, $contact, $old, $new) = @_;
		 print "presence_update ".($old // $new // $contact)->jid."\n";

		 # check if I'm connected elsewhere, and abort
		 return unless $new;

		 my $bare = bare_jid($acc->jid);
		 if (bare_jid($new->jid) eq $bare
		     and $new->jid ne $acc->jid
		     and $new->show and $new->show eq "chat"
		    ) {
		     if ($new->priority >= $mypriority) {
			 print "Connected elsewhere ".$new->jid."(".$new->priority." >= ".$mypriority."), aborting\n";
			 $cl->disconnect();
		     }
		 }
	     },

	     message => sub {
		 my ($cl, $acc, $msg) = @_;
		 my $body = $msg->any_body // "";
		 print "message: '".$body."' from '".$msg->from."'\n";
		 return unless $body;
		 my $params = XMPputer::Commands::Parameters->new(msg => $body,
								  from => $msg->from,
								  acl => $acl,
								  muc => $muc,
								  account => $account,
								  commands => $commands,
								 );
		 my $reply = $commands->answer($params);
		 if ($reply) {
		     my $repl = $msg->make_reply;
		     $repl->add_body($reply);
		     $repl->send;
		     print "replied (to ".$repl->to."): $reply\n";
		 }
	     },

	     contact_request_subscribe => sub {
		 my ($cl, $acc, $roster, $contact) = @_;
		 my $subscription = $contact->subscription // "none";
		 print "subscribe request by ".$contact->jid." (current: $subscription)\n";
		 if ($subscription ne "both") {
		     $contact->send_subscribed();
		 }
	     },

	     error => sub {
		 my ($cl, $acc, $error) = @_;
		 warn "Error encountered: ".$error->string."\n";
		 $cv->broadcast;
	     },

	     #connect => sub {
	     #    print "connect\n";
	     #    use Data::Dumper; print Dumper([map {ref $_} @_]);
	     #},

	     disconnect => sub {
		 my ($cl, $acc, @rest) = @_;
	         print "disconnect (".$acc->jid.")\n";
	         $cv->broadcast;
	     },
	    );

$cl->start;
$cv->wait;

print "bye bye!\n";
exit 0;
