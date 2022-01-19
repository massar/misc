#!/usr/bin/perl -w
# type65_https.pl by Jeroen Massar
#
# Create a TYPE65 DNS RR Record for HTTPS (DNS SVCB and HTTPS RRs)
# for use in BIND, NSD, PowerDNS till they have native RRType HTTPS and SCVB support.
#
# This uses Perl Net::DNS 1.26+ by Willem Toorop of NLNetLabs, see https://metacpan.org/pod/Net::DNS
# Thanks to Willem for all the actual hard work.
#
# The RRTypes are defined in:
# https://github.com/MikeBishop/dns-alt-svc/blob/master/draft-ietf-dnsop-svcb-https.md
#
# and currently primarily requested by Apple's iOS14
#
# Usage Examples:
# perl type65_https.pl 'example.net HTTPS 1 . alpn="h3,h2" ipv4hint="192.0.2.42" ipv6hint="2001:db8::42"'
# perl type65_https.pl 'example.org HTTPS 0 example.net'

use strict;
use vars qw($opt_r);

use Net::DNS;

type65(@ARGV);
exit;

sub type65 {
	my $arg = join(' ', @_);

	my $rr = Net::DNS::RR->new($arg);

	print $rr->generic()."\n";
}
