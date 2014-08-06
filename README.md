misc
====

Misc scripts and other doodles to keep around

backup
------
Rsync hardlinking backup script along with a cleanup script that deletes old archives keeping every 2 weeks etc

calendar.example.org
--------------------

An example SabreDAV CalDAV server using nginx+php-fpm that works fine with iCal, iPhones etc.

check_gtube
-----------

This script tests if GTUBE messages are passed through sendmail + spamassassin/spamass-milter.
If the message gets rejected it is considered fine, otherwise critical is raised.

The result can be hooked into nagios so that one can test if the spam-checker still works.
(sometimes spamass-milter fails/stops and/or you just forget to configure it to reject...)

closedexec
----------
Simple closedexec forcer so that open sockets don't stay open for childs.

This was useful in PHP which was linked inside Apache, if one then did an exec() of sorts even port 80 would go to the forked process and thus port 80 would be occupied when one would restart Apache and then Apache would not start, the process would die and you did not have a webserver... very nasty especially because log rotations used to cause restarts

customfiles
-----------
Have a box that is up and running 'forever', wondering what the difference is with a base Debian installation?

This little perl script will try to figure out what is different compared to the Debian packages that are installed.
Based on those differences one should then create a puppet/cfengine/ansible/etc module to automate the installation.
Of course, it also simply allows one to identify what files to backup and what is base and thus can be skipped.

fuzgoogle
---------
Google interface for Eggdrop

rangeban
--------
Simple rangeban script for eggdrop, allows banning based on CIDR prefixes

ratelimit
----------
Ratelimiting script

- uses new conntrack (xt_CT) module instead of old 'conntrack' module
- uses a separate chain for permanent blocking and the actual ratelimiting
- multiple ports can be specified with help from the multiport module

spamcalc
--------
Little spamcalc script for eggdrops, to directly call the spamcalc command when a host joins

windows_dynamicdns_update
-------------------------
A way to do DNS updates on Windows
