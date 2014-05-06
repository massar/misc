#!/bin/sh

USER=username
PASS=somepassword
EMAIL=username@example.org
REALNAME="Full User Name"

##################
SQL="sqlite3 ../data/calendars.sqlite"
REALM=calendar.example.org

PW=$(echo -n '${USER}:${REALM}:${PASS}' | md5sum)

echo "INSERT INTO users (username,digesta1) VALUES('${USER}', '${PW}');" | ${SQL}
echo "INSERT INTO principals (uri,email,displayname) VALUES ('principals/${USER}', '${EMAIL}','${REALNAME}');" | ${SQL}
echo "INSERT INTO principals (uri,email,displayname) VALUES ('principals/${USER}/calendar-proxy-read', null, null);" | ${SQL}
echo "INSERT INTO principals (uri,email,displayname) VALUES ('principals/${USER}/calendar-proxy-write', null, null);" | ${SQL}

echo "INSERT INTO addressbooks (principaluri, displayname, uri, description, ctag) VALUES ('principals/${USER}','Default Addressbook','default','','1');" | ${SQL}


