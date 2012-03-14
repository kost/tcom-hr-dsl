#!/usr/bin/perl
# T-com IP History. Copyright (C) Kost. Distributed under GPL.

use strict;
use WWW::Mechanize;
use Getopt::Long;

my $configfile="$ENV{HOME}/.tcom";
my %config;
$config{'baseurl'} = 'https://user.t-com.hr/';
$config{'uri'} = 'adsl_ispis_spajanja.php?';
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
	"a|all" => \$config{'allformats'},
	"c|csv" => \$config{'csv'},
	"m|html" => \$config{'html'},
	"l|last" => \$config{'lastmonth'},
	"t|txt" => \$config{'txt'},
	"u|user=s" => \$config{'username'},
	"p|password=s" => \$config{'password'},
	"s|verifyssl!" => \$config{'verifyssl'},
	"o|out=s" => \$config{'out'},
	"v|verbose+"  => \$config{'verbose'},
	"h|help" => \&help
);

if ($config{'allformats'}) {
	$config{'csv'}=1;
	$config{'html'}=1;
	$config{'txt'}=1;
} else {
	unless ($config{csv} or $config{html} or $config{txt}) {
		$config{txt}=1;
	}
}

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

my $request;
my $burl=$config{'baseurl'}.$config{'uri'};
$burl=$burl.'lastmonth=true&' if ($config{'lastmonth'});
my %output;

if (($config{'txt'}) or ($config{'csv'})) {
	$request=$burl.'textdump=true&';
	$agent->get($request);
	my $resp = $agent->response()->content();
	if ($config{'txt'}) {
		$output{'txt'} = $resp;
	}
	if ($config{'csv'}) {
		$output{'csv'} = $resp;
		$output{'csv'} =~ s/\t/;/g;
	}
}

if ($config{'html'}) {
	$request=$burl;
	$agent->get($request);
	$output{'html'} = $agent->response()->content();
}

foreach my $type ( keys %output )
{
	print STDERR "[v] Output $type\n" if ($config{'verbose'}>2);
	if ($config{'out'}) {
		my $fn=$config{'out'}.'.'.$type;
		print STDERR "[v] Output $type to file: $fn\n" if ($config{'verbose'}>2);
		open(OUT,">$fn") or die ("cannot open $fn for writting: $!");
		print OUT $output{$type};	
		close(OUT);
	} else {
		print $output{$type};
	}
}

sub help {
	print "T-com IP History. Copyright (C) Kost. Distributed under GPL.\n\n";
	print "Usage: $0 -u <username> -p <password> [options]  \n";
	print "\n";
	print " -u <s>	Use username <s>\n";
	print " -p <s>	Use password <s>\n";
	print " -l	display for last month\n";
	print " -s	verify SSL cert\n";
	print " -c 	CVS output\n";
	print " -m	HTML output\n";
	print " -t	textdump output\n";
	print " -a	all outputs\n";
	print " -o <f>	output to file <f>\n";
	print " -v	verbose (-vv will be more verbose)\n";
	print "\n";

	print "Example: $0 -u user -p password -c\n";
	print "Example: $0 -c # with username and password in $configfile\n";
	
	exit 0;
}
