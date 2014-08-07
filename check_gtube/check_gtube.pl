#!/usr/bin/perl
# nagios: -epn
###################################################################
# check_gtube.pl by Jeroen Massar <jeroen@massar.ch>
#                for PaPHosting (http://www.paphosting.net)
###################################################################
# Available from https://github.com/massar/misc/check_gtube/
#
# This script tests if GTUBE messages are passed through
# sendmail + spamassassin/spamass-milter.
#
# If the message gets rejected it
# is considered fine, otherwise critical is raised.
###################################################################

use strict;
use warnings;
use IO::Socket::SSL qw(SSL_VERIFY_NONE);
use POSIX qw(strftime);
use Getopt::Long;
use Net::SMTP;
use Net::SMTP::SSL;
use Net::Domain qw(hostfqdn);

my $opts = {
	'debug'		=> 0,
	'smtp-server'	=> "",
	'smtp-port'	=> 25,
	'smtp-timeout'	=> 100,
	'smtp-ssl'	=> 0,
	'smtp-starttls'	=> 0,
	'mail-from'	=> "<>",
	'mail-to'	=> "",
	'mail-subject'	=> "Nagios GTUBE test",
	'hello'		=> hostfqdn
};

Getopt::Long::Configure(qw{no_auto_abbrev no_ignore_case_always});
GetOptions(
	"hostname|node|n=s"	=> \$opts->{'smtp-server'},
	"port|p=i"		=> \$opts->{'smtp-port'},
	"recipient|r=s"		=> \$opts->{'mail-to'},
	"ssl"			=> \$opts->{'smtp-ssl'},
	"starrtls|t"		=> \$opts->{'smtp-starttls'},
	"subject|s=s"		=> \$opts->{'mail-subject'},
	"verbose|v+"		=> \$opts->{'debug'})
	or usage();

# Require a hostname
usage() unless ($opts->{'smtp-server'} ne "" || $opts->{'mail-to'} ne "");

# Connect to SMTP
my $smtp = Net::SMTP->new(
		$opts->{'smtp-server'},
		Port => $opts->{'smtp-port'},
		Timeout => $opts->{'smtp-timeout'},
		Debug => $opts->{'debug'},
		Hello => $opts->{'hello'}
	);

nagios_critical("Could not init SMTP object $@") unless defined $smtp;

if ($opts->{'smtp-ssl'}) {
	$smtp = Net::SMTP::SSL->start_SSL(
		$smtp,
		SSL_verify_mode => SSL_VERIFY_NONE
	);

	nagios_critical("Could not connect with SSL")
		unless $smtp->code == 220;

} elsif ($opts->{'smtp-starttls'}) {
	$smtp->command('STARTTLS');
	$smtp->response();
	nagios_critical("Could not start TLS")
		unless $smtp->code == 220;

	$smtp = Net::SMTP::SSL->start_SSL(
			$smtp,
			SSL_verify_mode => SSL_VERIFY_NONE
			);
}

# Send a SPAM mail (GTUBE) that should be rejected
$smtp->mail($opts->{'mail-from'});
nagios_critical($smtp->message()) unless $smtp->ok();

$smtp->to($opts->{'mail-to'});
nagios_critical($smtp->message()) unless $smtp->ok();

$smtp->data(
	"From: " . $opts->{'mail-from'} . "\n".
	"To: " . $opts->{'mail-to'} . "\n".
	"Subject: " . $opts->{'mail-subject'} . "\n".
	rfc2822_date() . "\n".
	rfc2822_msgid() . "\n".
	"Precedence: junk\n".
	"MIME-Version: 1.0\n".
	"Content-Type: text/plain; charset=us-ascii\n".
	"Content-Transfer-Encoding: 7bit\n".
	"X-Mailer: Nagios GTUBE Tester (https://github.com/massar/misc/check_gtube/)\n".
	"\n".
	"This is the GTUBE, the\n".
	"	Generic\n".
	"	Test for\n".
	"	Unsolicited\n".
	"	Bulk\n".
	"	Email\n".
	"\n".
	"If your spam filter supports it, the GTUBE provides a test by which you\n".
	"can verify that the filter is installed correctly and is detecting incoming\n".
	"spam. You can send yourself a test mail containing the following string of\n".
	"characters (in upper case and with no white spaces and line breaks):\n".
	"\n".
	"XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X\n".
	"\n".
	"You should send this test mail from an account outside of your network.\n".
	"\n");

nagios_critical("Spam not blocked: ".$smtp->message()) unless $smtp->code() == 550;

nagios_ok("Mail service is rejecting spam");
exit 0;

# The end

sub nagios_ok {
	my ($msg) = @_;
	$msg =~ tr{\n}{/};
	print "OK - ".$msg;
	exit 0;
}

sub nagios_critical {
	my ($msg) = @_;
	$msg =~ tr{\n}{/};
	print "CRITICAL - ".$msg;
	exit 2;
}

# RFC 2822 date
sub rfc2822_date {
	return strftime("Date: %a, %e %b %Y %H:%M:%S %z (%Z)", gmtime);
}

# RFC 2822 message id
sub rfc2822_msgid {
	my $hostname = `hostname`;
	chomp $hostname;
	return "Message-ID: <" . rand(0xffffffff) . ".nagios@" . $hostname . ">";
}

sub usage {
	print	"Usage:\n".
		"./check_gtube.pl -r <recipient> -h <hostname> [options]\n".
		"\n".
		"-n	--hostname	specify a SMTP server\n".
		"-p	--port		specify a SMTP port\n".
		"-r	--recipient	specify a recipient\n".
		"	--ssl		enable SSL\n".
		"-t	--starrtls	enable starttls\n".
		"-s	--subject	specify a subject\n".
		"-v	--verbose	enable verbosity/debugging\n".
		"\n".
		"Connects to <hostname> port 25 (SMTP) and executes SMTP commands\n".
		"in an attempt to send the GTUBE spam mail through our PapMX.\n".
		"\n".
		"Examples:\n".
		"./check_gtube.pl -r you\@example.com -n mail.example.com\n".
		"./check_gtube.pl -r you\@example.com -n mail.example.com\n".
		"./check_gtube.pl -r you\@example.com -n mail.example.com -s \"Testing\"\n".
		"./check_gtube.pl -r you\@example.com -n mail.example.com --ssl -p 465\n".
		"\n";
	exit 1;
}

