#!/usr/bin/perl
# T-com IP. Copyright (C) Kost. Distributed under GPL.

use strict;
use WWW::Mechanize;
use Getopt::Long;

my $configfile="$ENV{HOME}/.tcom";
my %config;
$config{'baseurl'} = 'https://user.t-com.hr/';
$config{'agent'} = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:10.0.2) Gecko/20100101 Firefox/10.0.2';
$config{'verbose'}=0;

if (-e $configfile) {
	open(CONFIG,"<$configfile") or next;
	while (<CONFIG>) {
	    chomp;                  # no newline
	    s/#.*//;                # no comments
	    s/^\s+//;               # no leading white
	    s/\s+$//;               # no trailing white
	    next unless length;     # anything left?
	    my ($var, $value) = split(/\s*=\s*/, $_, 2);
	    $config{$var} = $value;
	} 
	close(CONFIG);
}

Getopt::Long::Configure ("bundling");

my $result = GetOptions (
	"t|time" => \$config{'timestamp'},
	"u|user=s" => \$config{'username'},
	"p|password=s" => \$config{'password'},
	"s|verifyssl!" => \$config{'verifyssl'},
	"v|verbose+"  => \$config{'verbose'},
	"h|help" => \&help
);

my $agent = WWW::Mechanize->new(
	stack_depth => 0,
	ssl_opts => {
		verify_hostname => $config{'verifyssl'},
	}
);
$agent->agent($config{'agent'});

if ($config{'verbose'}>10) {
	$agent->add_handler("request_send",  sub { shift->dump; return });
	$agent->add_handler("response_done", sub { shift->dump; return });
}

$agent->get($config{'baseurl'});

if ($config{'debug'}) {
	$agent->dump_forms;
}

$agent->submit_form(
        form_name => 'loginform',
        fields    => { username  => $config{'username'}, passwd => $config{'password'} },
        button    => 'Submit'
    );

my $resp = $agent->response()->content();

$resp =~ m%IP adresa:</td><td bgcolor=#ffffff><b>(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})</b></td></tr></table>%;

print $1;
if ($config{'timestamp'}) {
	$resp =~ m%veze<font color=#ff6600>*</font>:</td><td bgcolor=#ffffff width=220><b>([0-9.: ]*)</b></td></tr><tr>%;
	print ";".$1;
}
print "\n";

sub help {
	print "T-com IP. Copyright (C) Kost. Distributed under GPL.\n\n";
	print "Usage: $0 -u <username> -p <password> [options]  \n";
	print "\n";
	print " -u <s>	Use username <s>\n";
	print " -p <s>	Use password <s>\n";
	print " -s	verify SSL cert\n";
#	print " -t	provide timestamp\n";
	print " -v	verbose (-vv will be more verbose)\n";
	print "\n";

	print "Example: $0 -u user -p password -c\n";
	print "Example: $0 # with username and password in $configfile\n";
	
	exit 0;
}
