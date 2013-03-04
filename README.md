misc
====

Misc scripts and other doodles to keep around

closedexec
----------
Simple closedexec forcer so that open sockets don't stay open for childs.

This was useful in PHP which was linked inside Apache, if one then did an exec() of sorts even port 80 would go to the forked process and thus port 80 would be occupied when one would restart Apache and then Apache would not start, the process would die and you did not have a webserver... very nasty especially because log rotations used to cause restarts

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
