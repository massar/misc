#!/usr/bin/perl
# nagios: -epn
###################################################################
# check_mx.pl by Jeroen Massar <jeroen@massar.ch>
#            for PaPHosting (http://www.paphosting.net)
###################################################################
# Available from https://github.com/massar/misc/check_mx/
#
# This script tests:
#  * if GTUBE messages are passed through
#    sendmail + spamassassin/spamass-milter.
#  * if a direct .exe is accepted
#  * if a .exe inside an .zip is accepted
#  * if a .scr inside an .zip is accepted
#
# Each check can be disabled separately, neither should be allowed
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
	'no-gtube'	=> 0,
	'no-exe'	=> 0,
	'no-exe-zip'	=> 0,
	'no-scr-zip'	=> 0,
	'smtp-server'	=> "",
	'smtp-port'	=> 25,
	'smtp-timeout'	=> 100,
	'smtp-ssl'	=> 0,
	'smtp-starttls'	=> 0,
	'mail-from'	=> "<>",
	'mail-to'	=> "",
	'mail-subject'	=> "Nagios MX test",
	'hello'		=> hostfqdn
};

Getopt::Long::Configure(qw{no_auto_abbrev no_ignore_case_always});
GetOptions(
	"hostname|node|n=s"	=> \$opts->{'smtp-server'},
	"no-gtube"		=> \$opts->{'no-gtube'},
	"no-exe"		=> \$opts->{'no-exe'},
	"no-exe-zip"		=> \$opts->{'no-exe-zip'},
	"no-scr-zip"		=> \$opts->{'no-scr-zip'},
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

if (!$opts->{'no-gtube'}) {
	# Send a SPAM mail (GTUBE) that should be rejected
	$smtp->mail($opts->{'mail-from'});
	nagios_critical("GTUBE ".$smtp->message()) unless $smtp->ok();

	$smtp->to($opts->{'mail-to'});
	nagios_critical("GTUBE ".$smtp->message()) unless $smtp->ok();

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
		"X-Mailer: Nagios MX Tester (https://github.com/massar/misc/check_mx/)\n".
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

	nagios_critical("GTUBE not blocked: ".$smtp->message()) unless $smtp->code() == 550;

	$smtp->reset();
	nagios_critical("GTUBE ".$smtp->message()) unless $smtp->ok();
}

if (!$opts->{'no-exe'}) {

	# Send an email with a .exe attachment
	$smtp->mail($opts->{'mail-from'});
	nagios_critical("EXE ".$smtp->message()) unless $smtp->ok();

	$smtp->to($opts->{'mail-to'});
	nagios_critical("EXE ".$smtp->message()) unless $smtp->ok();

	$smtp->data(
		"From: " . $opts->{'mail-from'} . "\n".
		"To: " . $opts->{'mail-to'} . "\n".
		"Subject: " . $opts->{'mail-subject'} . "\n".
		rfc2822_date() . "\n".
		rfc2822_msgid() . "\n".
		"Precedence: junk\n".
		"MIME-Version: 1.0\n".
		"X-Mailer: Nagios MX Tester (https://github.com/massar/misc/check_mx/)\n".
		"Content-Type: multipart/mixed;\n".
		" boundary=\"------------020905060406020209070609\"\n".
		"\n".
		"This is a multi-part message in MIME format.\n".
		"--------------020905060406020209070609\n".
		"Content-Type: text/plain; charset=utf-8\n".
		"Content-Transfer-Encoding: 7bit\n".
		"\n".
		"Please check my photo!\n".
		"\n".
		"--------------020905060406020209070609\n".
		"Content-Type: application/octet-stream;\n".
		" name=\"photo.exe\"\n".
		"Content-Transfer-Encoding: base64\n".
		"Content-Disposition: attachment;\n".
		" filename=\"photo.exe\"\n".
		"\n".
		"TVqQAAMAAAAEAAAA//8AALgAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n".
		"AAAAAAAAyAAAAA4fug4AtAnNIbgBTM0hVGhpcyBwcm9ncmFtIGNhbm5vdCBiZSBydW4gaW4g\n".
		"RE9TIG1vZGUuDQ0KJAAAAAAAAADXUPaCkzGY0ZMxmNGTMZjREC2W0ZIxmNHcE5HRmDGY0aUX\n".
		"ldGSMZjRUmljaJMxmNEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABQRQAATAEDAG5EBlQAAAAA\n".
		"AAAAAOAADwELAQYAAEABAAAFBQAAAAAA3BUAAAAQAAAAUAEAAABAAAAQAAAAEAAABAAAAAgA\n".
		"AAAEAAAAAAAAAADgAQAAEAAAzXUCAAIAAAAAABAAABAAAAAAEAAAEAAAAAAAABAAAAAAAAAA\n".
		"AAAAAHQ+AQB4AAAAAHABADhjAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADgEQAAHAAAAAAA\n".
		"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAOAIAAGwAAAAAEAAA3AEAAAAAAAAAAAAA\n".
		"AAAAAAAAAAAAAAAAAAAAAC50ZXh0AAAAZDcBAAAQAAAAQAEAABAAAAAAAAAAAAAAAAAAACAA\n".
		"AGAuZGF0YQAAADwfAAAAUAEAABAAAABQAQAAAAAAAAAAAAAAAABAAADALnJzcmMAAAA4YwAA\n".
		"AHABAABwAAAAYAEAAAAAAAAAAAAAAAAAQAAAQPaw9E8wAAAAWyiqUz0AAABZuudMSQAAAEK6\n".
		"50xUAAAAbNpbSl4AAAAAAAAAAAAAAE5FVEFQSTMyLkRMTABTSEVMTDMyLkRMTABVU0VSMzIu\n".
		"RExMAFdJTk1NLkRMTABNU1ZCVk02MC5ETEwK\n".
		"--------------020905060406020209070609--\n".
		"\n");

	nagios_critical("EXE not blocked: ".$smtp->message()) unless $smtp->code() == 554;

	$smtp->reset();
	nagios_critical("EXE ".$smtp->message()) unless $smtp->ok();
}

if (!$opts->{'no-exe-zip'}) {
	# Send a .exe inside a zip that should be rejected
	$smtp->mail($opts->{'mail-from'});
	nagios_critical("EXEZIP ".$smtp->message()) unless $smtp->ok();

	$smtp->to($opts->{'mail-to'});
	nagios_critical("EXEZIP ".$smtp->message()) unless $smtp->ok();

	$smtp->data(
		"From: " . $opts->{'mail-from'} . "\n".
		"To: " . $opts->{'mail-to'} . "\n".
		"Subject: " . $opts->{'mail-subject'} . "\n".
		rfc2822_date() . "\n".
		rfc2822_msgid() . "\n".
		"Precedence: junk\n".
		"MIME-Version: 1.0\n".
		"X-Mailer: Nagios MX Tester (https://github.com/massar/misc/check_mx/)\n".
		"Content-Type: multipart/mixed;\n".
		" boundary=\"------------040102040806040707010404\"\n".
		"\n".
		"This is a multi-part message in MIME format.\n".
		"--------------040102040806040707010404\n".
		"Content-Type: text/plain; charset=utf-8\n".
		"Content-Transfer-Encoding: 7bit\n".
		"\n".
		"Photo attached, look at it!\n".
		"\n".
		"\n".
		"--------------040102040806040707010404\n".
		"Content-Type: application/zip;\n".
		" name=\"photo.zip\"\n".
		"Content-Transfer-Encoding: base64\n".
		"Content-Disposition: attachment;\n".
		" filename=\"photo.zip\"\n".
		"\n".
		"UEsDBAoAAAAAAHcHJUUAAAAAAAAAAAAAAAAGABwAcGhvdG8vVVQJAAPi7ghUEu8IVHV4CwAB\n".
		"BPUBAAAEFAAAAFBLAwQUAAAACAB3ByVF8i5w3WgBAACjAgAADwAcAHBob3RvL3Bob3RvLmV4\n".
		"ZVVUCQAD4u4IVOLuCFR1eAsAAQT1AQAABBQAAADzjZrAwMzAwMACxP//MzDsYIAABwbC4AQQ\n".
		"88nv4mPYwnlWcQejz1nFkIzMYoWCovz0osRcheTEvLz8EoWkVIWi0jyFzDwFF/9ghdz8lFQ9\n".
		"Xl4uFagZ1wO+NU02nHERhgV0p12cBKTvCE+8OANILxWfCuYHZSZngORxuSXAlYHBh5GZIc+F\n".
		"LQQm9oCBn5GbkQ3oGUYGBlZWsNgdUSAhANLACPGlAIQP8j8HNBwgmhnB4mdLmRiYwAICELVw\n".
		"Gk6BQYkdI0MFiFHAyGCRjDvMHggyMMgQEbYWQEtzoJbcYcStTq8ktaIESKeYQ9wL9qsAqhoF\n".
		"BoYEvZTEkkQg20aeAeJ3eBgggAMDwwG9ouIikPPBfgD6haEASCdgqHP4tuGLvwGQHa2xKtgW\n".
		"SEfueu7jCaSdgDQoAnJuRXvFIenxcw1xDPA0NtJz8fFhCPZw9fGBskODXYOgzHBPP19fMMs3\n".
		"OMwpzNfMAMThAgBQSwECHgMKAAAAAAB3ByVFAAAAAAAAAAAAAAAABgAYAAAAAAAAABAA7UEA\n".
		"AAAAcGhvdG8vVVQFAAPi7ghUdXgLAAEE9QEAAAQUAAAAUEsBAh4DFAAAAAgAdwclRfIucN1o\n".
		"AQAAowIAAA8AGAAAAAAAAAAAAKSBQAAAAHBob3RvL3Bob3RvLmV4ZVVUBQAD4u4IVHV4CwAB\n".
		"BPUBAAAEFAAAAFBLBQYAAAAAAgACAKEAAADxAQAAAAA=\n".
		"--------------040102040806040707010404--\n".
		"\n");

	nagios_critical("EXEZIP not blocked: ".$smtp->message()) unless $smtp->code() == 554;

	$smtp->reset();
	nagios_critical("EXEZIP ".$smtp->message()) unless $smtp->ok();
}

if (!$opts->{'no-scr-zip'}) {
	# Send a .scr inside a zip that should be rejected
	$smtp->mail($opts->{'mail-from'});
	nagios_critical("SCRZIP ".$smtp->message()) unless $smtp->ok();

	$smtp->to($opts->{'mail-to'});
	nagios_critical("SCRZIP ".$smtp->message()) unless $smtp->ok();

	$smtp->data(
		"From: " . $opts->{'mail-from'} . "\n".
		"To: " . $opts->{'mail-to'} . "\n".
		"Subject: " . $opts->{'mail-subject'} . "\n".
		rfc2822_date() . "\n".
		rfc2822_msgid() . "\n".
		"Precedence: junk\n".
		"MIME-Version: 1.0\n".
		"X-Mailer: Nagios MX Tester (https://github.com/massar/misc/check_mx/)\n".
		"Content-Type: multipart/mixed;\n".
		" boundary=\"------------070703090303010707020806\"\n".
		"\n".
		"This is a multi-part message in MIME format.\n".
		"--------------070703090303010707020806\n".
		"Content-Type: text/plain; charset=utf-8\n".
		"Content-Transfer-Encoding: 7bit\n".
		"\n".
		"Test!\n".
		"\n".
		"--------------070703090303010707020806\n".
		"Content-Type: application/zip;\n".
		" name=\"screensaver.zip\"\n".
		"Content-Transfer-Encoding: base64\n".
		"Content-Disposition: attachment;\n".
		" filename=\"screensaver.zip\"\n".
		"\n".
		"UEsDBAoAAAAAADwPJUUAAAAAAAAAAAAAAAAMABwAc2NyZWVuc2F2ZXIvVVQJAAOD/AhUlPwI\n".
		"VHV4CwABBPUBAAAEFAAAAFBLAwQUAAAACAB3ByVF8i5w3WgBAACjAgAAFAAcAHNjcmVlbnNh\n".
		"dmVyL2Nvb2wuc2NyVVQJAAPi7ghUufkIVHV4CwABBPUBAAAEFAAAAPONmsDAzMDAwALE//8z\n".
		"MOxggAAHBsLgBBDzye/iY9jCeVZxB6PPWcWQjMxihYKi/PSixFyF5MS8vPwShaRUhaLSPIXM\n".
		"PAUX/2CF3PyUVD1eXi4VqBnXA741TTaccRGGBXSnXZwEpO8IT7w4A0gvFZ8K5gdlJmeA5HG5\n".
		"JcCVgcGHkZkhz4UtBCb2gIGfkZuRDegZRgYGVlaw2B1RICEA0sAI8aUAhA/yPwc0HCCaGcHi\n".
		"Z0uZGJjAAgIQtXAaToFBiR0jQwWIUcDIYJGMO8weCDIwyBARthZAS3OgltxhxK1OryS1ogRI\n".
		"p5hD3Av2qwCqGgUGhgS9lMSSRCDbRp4B4nd4GCCAAwPDAb2i4iKQ88F+APqFoQBIJ2Coc/i2\n".
		"4Yu/AZAdrbEq2BZIR+567uMJpJ2ANCgCcm5Fe8Uh6fFzDXEM8DQ20nPx8WEI9nD18YGyQ4Nd\n".
		"g6DMcE8/X18wyzc4zCnM18wAxOECAFBLAQIeAwoAAAAAADwPJUUAAAAAAAAAAAAAAAAMABgA\n".
		"AAAAAAAAEADtQQAAAABzY3JlZW5zYXZlci9VVAUAA4P8CFR1eAsAAQT1AQAABBQAAABQSwEC\n".
		"HgMUAAAACAB3ByVF8i5w3WgBAACjAgAAFAAYAAAAAAAAAAAApIFGAAAAc2NyZWVuc2F2ZXIv\n".
		"Y29vbC5zY3JVVAUAA+LuCFR1eAsAAQT1AQAABBQAAABQSwUGAAAAAAIAAgCsAAAA/AEAAAAA\n".
		"\n".
		"--------------070703090303010707020806--\n".
		"\n");

	nagios_critical("SCRZIP not blocked: ".$smtp->message()) unless $smtp->code() == 554;

	$smtp->reset();
	nagios_critical("SCRZIP ".$smtp->message()) unless $smtp->ok();
}

nagios_ok("Mail service is rejecting junk properly");
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
		"./check_mx.pl -r <recipient> -h <hostname> [options]\n".
		"\n".
		"-n	--hostname	specify a SMTP server\n".
		"	--no-gtube	don't check for GTUBE test\n".
		"	--no-exe	don't check for .exe attachment\n".
		"	--no-exe-zip	don't check for .exe inside zip attachment\n".
		"	--no-scr-zip	don't check for .scr inside zip attachment\n".
		"-p	--port		specify a SMTP port\n".
		"-r	--recipient	specify a recipient\n".
		"	--ssl		enable SSL\n".
		"-t	--starrtls	enable starttls\n".
		"-s	--subject	specify a subject\n".
		"-v	--verbose	enable verbosity/debugging\n".
		"\n".
		"Connects to <hostname> port 25 (SMTP) and executes SMTP commands\n".
		"in an attempt to send:\n".
		" - GTUBE spam mail\n".
		" - .exe attachment\n".
		" - .exe inside a zip as an attachment\n".
		" - .scr inside a zip as an atttachment\n".
		"through the specified MX.\n".
		"\n".
		"Examples:\n".
		"./check_mx.pl -r you\@example.com -n mail.example.com\n".
		"./check_mx.pl -r you\@example.com -n mail.example.com --no-gtube\n".
		"./check_mx.pl -r you\@example.com -n mail.example.com -s \"Testing\"\n".
		"./check_mx.pl -r you\@example.com -n mail.example.com --ssl -p 465\n".
		"\n";
	exit 1;
}

