#!/bin/bash

################################################
## rsync-hardlink-based incremental backup
## ignoring most system/cache/etc files, LXC-aware
##
## Jeroen Massar <jeroen@massar.ch>
################################################

# Where we backup to (trailing slash required)
BACKUPDIR=/backup/

if [ $# -lt 2 ];
then
	echo "Usage: backup [user@]<host>[:/path/] <dirname>";
	echo "eg: backup host.example.com example.host"
	echo "    backup backupuser@otherhost.example.org example.otherhost"
	echo ""
	echo "Cron-job this as much as you want (eg hourly)"
	echo "You likely will want to setup ssh-keys for this ;)"
	exit;
fi

# Source
SRC=$1

# Destination
DST=${BACKUPDIR}$2/
LOCKFILE=/tmp/backup.$2

if test "${VERBOSE+set}" = set;
then
	echo "Backing up ${SRC} => ${DST}"
fi

shift
shift

# Do we want the full filesystem or only a specific part?
if [ ${SRC:0:1} != "/" ];
then
	TST=`echo ${SRC} | cut -f2 -d:`
	if [ "${TST}" = "${SRC}" ];
	then
		SRC=${SRC}:/
	fi
fi

# Avoid running more than one at a time
if [ -x /usr/bin/lockfile-create ] ; then
    lockfile-create $LOCKFILE
    if [ $? -ne 0 ] ; then
        cat <<EOF

Unable to run (cronned?) backup because lockfile $LOCKFILE
acquisition failed. This probably means that the previous instance
is still running. Please check and correct if necessary.

EOF
        exit 1
    fi

    # Keep lockfile fresh
    lockfile-touch $LOCKFILE &
    LOCKTOUCHPID="$!"
fi

# Exclusions
EXCL_LIST="/proc /cgroup /cdrom /dev /sys /mnt /media /var/lib/php5 /var/run/ /run /var/cache/apt/archives/ /var/log/ /bin /sbin /boot /initrd /lib /lib64 /usr /var/cache /selinux"

EXCL=
for e in ${EXCL_LIST};
do
	EXCL="${EXCL} --exclude ${e} --exclude '/var/lib/lxc/*/rootfs${e}'"
done

# The date we tag this as
date=`date "+%Y-%m-%d_%H_%M"`

# Go the backup directory for this backup
mkdir -p ${DST}
cd ${DST}

RSYNCOPTS="-q"
if test "${VERBOSE+set}" = set;
then
	RSYNCOPTS="--progress --stats"
fi

if test "${NORELATIVE+set}" = set;
then
	RSYNCOPTS="${RSYNCOPTS} --no-relative"
else
	RSYNCOPTS="${RSYNCOPTS} -R"
fi

# Sync it over
nice -n 20 rsync -x ${RSYNCOPTS} --no-motd "$@" -e 'ssh -q' -a --partial --delete --delete-excluded ${EXCL} --link-dest=../current ${SRC} incomplete-${date}
ERR=$?

OK=no

case "$ERR" in
	0)
		# All okay
		OK=yes
		;;

	24)
		echo "Partial transfer, all should still be fine"
		OK=yes
		;;

	*)
		echo "Rsync gave error ${ERR} please verify that all is okay"
		;;
esac


if [ "${OK}" = "yes" ];
then
	mv incomplete-${date} backup-${date}
	rm -f current
	ln -s backup-${date} current
	if test "${VERBOSE+set}" = set;
	then
		echo "Backing up ${SRC} => ${DST}... done"
	fi
else
	echo "SRC = ${SRC}"
	echo "DST = ${DST}"
	echo "Did not move backup to current, please verify that all is okay"
	echo ""
fi

#
# Clean up lockfile
#
if [ -x /usr/bin/lockfile-create ] ; then
	kill $LOCKTOUCHPID
	lockfile-remove $LOCKFILE
fi

