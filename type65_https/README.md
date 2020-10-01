# type65_https.pl by Jeroen Massar

Create a TYPE65 DNS RR Record for HTTPS (DNS SVCB and HTTPS RRs)
for use in BIND, NSD, PowerDNS till they have native RRType HTTPS and SCVB support.

This uses Perl Net::DNS 1.26+ by Willem Toorop of NLNetLabs, see https://metacpan.org/pod/Net::DNS
Thanks to Willem for all the actual hard work of implementing the RRType.

The RRTypes are defined in:
https://github.com/MikeBishop/dns-alt-svc/blob/master/draft-ietf-dnsop-svcb-https.md
and currently primarily requested by Apple's iOS14, but others are to follow.

Note that the IPv4Hint/IPv6Hint is a hint, but it can bypass RPZ IP filters.

# Usage Examples

```
$ perl type65_https.pl 'example.net HTTPS 1 . alpn="h3,h2" ipv4hint="192.0.2.42" ipv6hint="2001:db8::42"'

example.net. TYPE65 ( \# 41 00010000010006026833026832000400
	04c000022a0006001020010db8000000 000000000000000042 )
```

```
$ perl type65_https.pl 'example.com HTTPS 1 example.net'
example.com. TYPE65 \# 15 0001076578616d706c65036e657400
```

