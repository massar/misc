rem @echo off
rem ##################################################################
rem Windows NT (NT4/2k/2k3) IPv4 & IPv6 Secure DNS Update Script
rem ##################################################################
rem Get the UnxUtils from http://unxutils.sourceforge.net/ and install them somewhere
rem Then adjust your path.
rem Get the nsupdate program + libs from ISC (www.isc.org), usually the bind9 distro.
rem Then copy over the K*.private & K*.key over for the host to your box.
rem Change the config below, et tada ;)
rem
rem Script by Jeroen Massar <jeroen@unfix.org>
rem
rem Note: it should probably use netsh, but oh well ;)

rem ##################################################################
rem Our config
rem ##################################################################
set HOSTNAME=limbo
set DOMAIN=unfix.org
set KEYFILE=C:\Programs\Net\Bind\Klimbo.unfix.org.+157+34970.key
set UNX=C:\Programs\System\Unix
set NSUPDATE=C:\Programs\Net\Bind\nsupdate
set SCRIPT=c:\Programs\Net\Bind\cmd.txt
set INTERFACE=4

rem ######################################################################
rem The Script
rem ######################################################################
rem Specify a sane DNS Server
rem Done because on NT nsupdate can't find /etc/resolv.conf that easily :)
%UNX%\echo -n "server" >%SCRIPT%
ipconfig /all | %UNX%\grep "DNS Servers" | %UNX%\cut -f2 -d: | %UNX%\head -n 1 >>%SCRIPT%

rem Delete the old ones
%UNX%\echo "update delete %HOSTNAME%.%DOMAIN% A" >>%SCRIPT%
%UNX%\echo "update delete %HOSTNAME%.%DOMAIN% AAAA" >>%SCRIPT%
%UNX%\echo "update delete %HOSTNAME%.ipv4.%DOMAIN% A" >>%SCRIPT%
%UNX%\echo "update delete %HOSTNAME%.ipv6.%DOMAIN% AAAA" >>%SCRIPT%

rem Add the IPv4 address.
%UNX%\echo -n "update add %HOSTNAME%.%DOMAIN% 360 A" >>%SCRIPT%
ipconfig /all | %UNX%\grep "IP Address" | %UNX%\cut -f2 -d: | %UNX%\head -n 1 >>%SCRIPT%
%UNX%\echo -n "update add %HOSTNAME%.ipv4.%DOMAIN% 360 A" >>%SCRIPT%
ipconfig /all | %UNX%\grep "IP Address" | %UNX%\cut -f2 -d: | %UNX%\head -n 1 >>%SCRIPT%

rem Add the IPv6 address.
%UNX%\echo -n "update add %HOSTNAME%.%DOMAIN% 360 AAAA " >>%SCRIPT%
ipv6 if %INTERFACE% | %UNX%\grep "preferred global" | %UNX%\awk "{print $3; }" | %UNX%\cut -f1 -d, >>%SCRIPT%
%UNX%\echo -n "update add %HOSTNAME%.ipv6.%DOMAIN% 360 AAAA " >>%SCRIPT%
ipv6 if %INTERFACE% | %UNX%\grep "preferred global" | %UNX%\awk "{print $3; }" | %UNX%\cut -f1 -d, >>%SCRIPT%

rem And send the update
%UNX%\echo "send" >>%SCRIPT%

%UNX%\echo %NSUPDATE% -k %KEYFILE% %SCRIPT%
