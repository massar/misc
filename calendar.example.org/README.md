# calendar.example.org - SabreDAV Calendar (CalDAV) Example with nginx

Github location: https://github.com/massar/misc/calendar.example.org/

This is a full SabreDAV Calendar example[1], using nginx / php-fpm as the server platform.

For more information about SabreDAV, check out [Sabre.io](http://sabre.io/)

As mentioned in conf/www.conf:
 Please do check [Better Crypto](http://bettercrypto.org) for lots of knob to tweak in the configurations

## Directory structure

The following directories are included in this package:

 * ```conf/``` - contains the nginx configuration include
 * ```data/``` - contains the sqlite database used by SabreDAV
 * ```inc/```  - contains links to the upstream git reps for SabreDAV
 * ```www/```  - contains the single index.php that calls SabreDAV to handle everything

## Installation

As several components have to be installed that run as different users some steps will have to be done as the root user.

git pull this into ```/www/calendar.example.org/``` so that this README.md is in that directory

If you want them somewhere else, you'll have to change the paths, rgrep for ```/www/``` and
change the paths where needed. You'll likely end up changing this anyway due to the hostname.

To install on your host:
```
apt-get install nginx php5-fpm php5-sqlite php5-curl git
```

Symlink the config file so that nginx knows where it is:
```
ln -s /www/calendar.example.org/conf/www.conf /etc/nginx/conf.d/calendar.example.org.conf
```

You'll need to ensure that the full ```/www/calendar.example.org``` tree is readable/accessiable
by the user php-fpm runs under. Typically this is ```www-data```, one can use a group where that
user is in and change the group appropriately and/or set it to read/write for world.

The ```/www/calendar.example.org/data/``` directory has to be readable, accessiable and writeable
by the user php-fpm runs under. Typically just chowning it to ```www-data``` will work great.
One could make that group not-accessible for 'other' if really wanted.

You'll need to arrange the SSL certificates from a CA. Most CA's have proper details
on how to request and setup these certificates, placing them in ```conf/ssl.{crt|key}```.

To generate the data/calendars.sqlite file, access ```https://calendar.example.org``` once.
Then you should have a new data/calendars.sqlite file. Use the ```conf/adduser.sh``` script
to add your first user.

